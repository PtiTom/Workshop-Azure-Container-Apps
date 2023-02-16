$RESOURCE_GROUP="RG_Lab_9_Tme"
$LOCATION="francecentral"
$ACR_NAME="acrlab9tme"
$ENVIRONMENT_NAME="Lab-9-env-tme"
$APPLICATION="hello-aca"
$VERSION_1_APPLICATION="1.0.0"
$REVISION_01="rev-01"
$VERSION_2_APPLICATION="2.0.0"
$REVISION_02="rev-02"

az group create --name $RESOURCE_GROUP --location $LOCATION
az group show --resource-group $RESOURCE_GROUP -o table
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true
az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP -o table
az containerapp env create --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --logs-destination none
az containerapp env list --resource-group $RESOURCE_GROUP -o jsonc

cd ./Lab_9/App
$compiledName = "$ACR_NAME.azurecr.io/$APPLICATION" + ":" + $VERSION_1_APPLICATION
az acr build -t $compiledName -r $ACR_NAME .
az acr repository list --name $ACR_NAME -o table

$REGISTRY_PASSWORD=(az acr credential show --name $ACR_NAME -o tsv --query "passwords[0].value")
az containerapp create --name $APPLICATION --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME --image $compiledName --revision-suffix $REVISION_01 --registry-server "$ACR_NAME.azurecr.io" --registry-username $ACR_NAME --registry-password $REGISTRY_PASSWORD --target-port 3000 --ingress 'external' --query properties.configuration.ingress.fqdn -o jsonc

$compiledName2 = "$ACR_NAME.azurecr.io/$APPLICATION" + ":" + $VERSION_2_APPLICATION
az acr build -t $compiledName2 -r $ACR_NAME .


az containerapp ingress traffic set --name $APPLICATION --resource-group $RESOURCE_GROUP --revision-weight $APPLICATION--$REVISION_01=0 $APPLICATION--$REVISION_02=100
$URL=(az containerapp show --name $APPLICATION --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv)`
curl https://$URL