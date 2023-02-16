$RESOURCE_GROUP="RG-Lab-TME"
$APPLICATION_NAME="node-api"

az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o table

$ACR_NAME="tmecontainerregistry"
$IMAGE_NAME=".azurecr.io/api/api:2.0.0"

az containerapp update --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP --image $ACR_NAME$IMAGE_NAME -o jsonc
az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o table
az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o jsonc

$REVISION_NAME=$(az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o tsv --query "[1].name")
echo $REVISION_NAME
az containerapp revision show --name $APPLICATION_NAME --revision $REVISION_NAME --resource-group $RESOURCE_GROUP -o jsonc

az containerapp show -n $APPLICATION_NAME -g $RESOURCE_GROUP -o jsonc --query properties.configuration

az containerapp show -n $APPLICATION_NAME -g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn

echo "https://$(az containerapp show -n $APPLICATION_NAME -g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)"


az containerapp revision label add --label "blue" --resource-group $RESOURCE_GROUP --revision $(az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o tsv --query "[0].name") --name $APPLICATION_NAME -o jsonc
az containerapp revision label add --label "green" --resource-group $RESOURCE_GROUP --revision $(az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o tsv --query "[1].name") --name $APPLICATION_NAME -o jsonc

az containerapp ingress traffic set --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP --label-weight blue=80 green=20 -o jsonc

for ($i = 0 ; $i -lt 30 ; $i++) {echo "https://$(az containerapp show -n $APPLICATION_NAME -g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)"}
for ((i=0; i<20; ++i)); do curl $(echo "https://$(az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)"); done