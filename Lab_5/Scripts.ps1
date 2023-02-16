$RESOURCE_GROUP="RG-Lab5-TME"
$LOCATION="francecentral"
$CONTAINERAPP_NAME="nginx-tme"
$CONTAINERAPPS_ENVIRONMENT="tme-environment-lab5"
$LOG_ANALYTICS_NAME="tme-workspace-lab5"

az group create --name $RESOURCE_GROUP --location $LOCATION -o table

az monitor log-analytics workspace create  --resource-group $RESOURCE_GROUP  --workspace-name $LOG_ANALYTICS_NAME  --location $LOCATION  -o jsonc

$LOG_ANALYTICS_WORKSPACE_CLIENT_ID=(az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv)

$LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY=(az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv)

az containerapp env create --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY -o jsonc

az containerapp create --name $CONTAINERAPP_NAME --resource-group $RESOURCE_GROUP --environment $CONTAINERAPPS_ENVIRONMENT --image "docker.io/nginx:latest" --target-port 80 --ingress 'external' --query properties.configuration.ingress.fqdn -o jsonc

