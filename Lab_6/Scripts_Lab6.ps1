







az ad sp create-for-rbac --name "Tme_SPN" --role "Contributor" --scopes /subscriptions/4f32bf2b-63b7-4905-89b6-eef631e52a18 --sdk-aut -o jsonc

{
  "clientId": "f2447e7f-542a-4446-b936-5bfe40702403",
  "clientSecret": "FKb8Q~LwM_P1bBChfZp.ZtfLDmym-yiDkuvM~akh",
  "subscriptionId": "4f32bf2b-63b7-4905-89b6-eef631e52a18",
  "tenantId": "4c953047-dc2c-45a1-a0e2-fa113c905fe6",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}


$RESOURCE_GROUP="RG-Lab6-TME"
$LOCATION="francecentral"
$ACR_NAME="acrtmelab6"
$LOG_ANALYTICS_NAME="tme-workspace-lab-6"
$CONTAINERAPPS_ENVIRONMENT="env-tme-lab-6"
$APPLICATION="hello"

az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

az acr create --resource-group ${RESOURCE_GROUP} --name ${ACR_NAME} --sku Basic --admin-enabled true

az monitor log-analytics workspace create --resource-group ${RESOURCE_GROUP} --workspace-name ${LOG_ANALYTICS_NAME} --location ${LOCATION}
$LOG_ANALYTICS_WORKSPACE_CLIENT_ID=(az monitor log-analytics workspace show --query customerId -g ${RESOURCE_GROUP} -n ${LOG_ANALYTICS_NAME} --out tsv)
$LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY=(az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g ${RESOURCE_GROUP} -n ${LOG_ANALYTICS_NAME} --out tsv)

az containerapp env create --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --location ${LOCATION} --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY
#"Build & Push" l'application
cd ./Lab_6/App
$compiledName = "${ACR_NAME}.azurecr.io/${APPLICATION}" + ":1.0.0"
az acr build -t $compiledName -r ${ACR_NAME} .
#Déploiement de l'application
az containerapp create --name ${APPLICATION} --resource-group ${RESOURCE_GROUP} --environment ${CONTAINERAPPS_ENVIRONMENT} --image $compiledName --target-port 3000 --ingress external --registry-server "${ACR_NAME}.azurecr.io" --query configuration.ingress.fqdn