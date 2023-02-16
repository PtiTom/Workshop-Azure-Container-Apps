$env:RESOURCE_GROUP="RG-Lab-TME"
$env:LOCATION="francecentral"
$env:CONTAINERAPPS_ENVIRONMENT="tme-environment"
$env:LOG_ANALYTICS_NAME="tme-workspace-lab"

$RESOURCE_GROUP="RG-Lab-TME"
$LOCATION="francecentral"
$CONTAINERAPPS_ENVIRONMENT="tme-environment"
$LOG_ANALYTICS_NAME="tme-workspace-lab"


az group create --name $RESOURCE_GROUP --location $LOCATION -o table


az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_NAME --location $LOCATION -o jsonc

$LOG_ANALYTICS_WORKSPACE_CLIENT_ID=(az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv)

$LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY=(az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv)

az containerapp env create --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY -o jsonc


$CONTAINERAPPS_NAME="tme-container-app"
az containerapp create --name $CONTAINERAPPS_NAME --resource-group $RESOURCE_GROUP --environment $CONTAINERAPPS_ENVIRONMENT --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest --target-port 80 --ingress 'external' --query properties.configuration.ingress.fqdn -o jsonc
$ACR_NAME="tmecontainerregistry"  
$ACR_SKU="Basic"
az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --sku $ACR_SKU --location $LOCATION -o table

az acr update --name $ACR_NAME --resource-group $RESOURCE_GROUP --admin-enabled true -o jsonc
az acr credential show --name $ACR_NAME -o jsonc
$REGISTRY_PASSWORD=$(az acr credential show --name $ACR_NAME -o tsv --query "passwords[0].value")


$APPLICATION_NAME="node-api"
az containerapp create -n $APPLICATION_NAME -g $RESOURCE_GROUP --image "$ACR_NAME.azurecr.io/api/api:1.0.0" --environment $CONTAINERAPPS_ENVIRONMENT --ingress external --target-port 3000 --registry-server "$ACR_NAME.azurecr.io" --registry-username $ACR_NAME --registry-password $REGISTRY_PASSWORD --revisions-mode multiple --cpu "0.75" --memory "1.5Gi" --min-replicas 2 --max-replicas 5 --query properties.configuration.ingress.fqdn -o jsonc

az containerapp show -n $APPLICATION_NAME -g $RESOURCE_GROUP -o jsonc