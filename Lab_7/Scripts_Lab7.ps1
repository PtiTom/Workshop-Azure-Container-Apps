$RESOURCE_GROUP="RG-Lab7-TME"
$LOCATION="francecentral"
$CONTAINERAPPS_ENVIRONMENT="my-env-tme"
$LOG_ANALYTICS_NAME="tme-workspace-lab"
$ACR_NAME="acrtmetest"
$CONTAINER_APP_NAME="my-container-app-tme"

az group create --name $RESOURCE_GROUP --location $LOCATION -o table
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_NAME --location $LOCATION -o jsonc
$LOG_ANALYTICS_WORKSPACE_CLIENT_ID=(az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv)
$LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY=(az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv)

az containerapp env create --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY -o jsonc

az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --sku Basic --location $LOCATION --admin-enabled true -o jsonc

$REGISTRY_PASSWORD=(az acr credential show -n $ACR_NAME -o tsv --query 'passwords[0].value')

az acr import --name $ACR_NAME --source "docker.io/stefanprodan/podinfo:latest" --image podinfo:latest

az containerapp create --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --environment $CONTAINERAPPS_ENVIRONMENT --image "$ACR_NAME.azurecr.io/podinfo:latest" --registry-server "$ACR_NAME.azurecr.io" --registry-username $ACR_NAME --registry-password $REGISTRY_PASSWORD --target-port 9898 --ingress 'external' --query properties.configuration.ingress.fqdn -o jsonc

az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --output yaml > app.yaml

(Get-Content app.yaml).Replace("minReplicas: null", "minReplicas: 2")|Set-Content app.yaml
az containerapp update --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --yaml app.yaml -o jsonc