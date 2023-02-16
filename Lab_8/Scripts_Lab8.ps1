$RESOURCE_GROUP="RG_Lab_8_TME"
$ENVIRONMENT_NAME="Lab-8-env-tme"
$LOCATION="francecentral"
$STORAGE_ACCOUNT_NAME="acastorageaccountlab8tme"
$STORAGE_SHARE_NAME="acafileshare00tme"
$STORAGE_MOUNT_NAME="acastoragemounttme"
$CONTAINER_APP_NAME="nginx-container-app-tme"

az group create --name $RESOURCE_GROUP --location $LOCATION
az group show --resource-group $RESOURCE_GROUP -o table
az containerapp env create --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --logs-destination none --location $LOCATION
az containerapp env show --resource-group $RESOURCE_GROUP --name $ENVIRONMENT_NAME -o table
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT_NAME --location $LOCATION --kind StorageV2 --sku Standard_LRS --enable-large-file-share
az storage account show --name $STORAGE_ACCOUNT_NAME -o table
az storage share-rm create --resource-group $RESOURCE_GROUP --storage-account $STORAGE_ACCOUNT_NAME --name $STORAGE_SHARE_NAME --quota 1024 --enabled-protocols SMB
az storage share-rm show --name $STORAGE_SHARE_NAME --storage-account $STORAGE_ACCOUNT_NAME -o table
$STORAGE_ACCOUNT_KEY=(az storage account keys list -n $STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)
echo $STORAGE_ACCOUNT_KEY
az containerapp env storage set --access-mode ReadWrite --azure-file-account-name $STORAGE_ACCOUNT_NAME --azure-file-account-key $STORAGE_ACCOUNT_KEY --azure-file-share-name $STORAGE_SHARE_NAME --storage-name $STORAGE_MOUNT_NAME --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP
az containerapp env storage show --resource-group $RESOURCE_GROUP --storage-name $STORAGE_MOUNT_NAME --name $ENVIRONMENT_NAME -o table
az containerapp create --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME --image nginx --min-replicas 1 --max-replicas 1 --target-port 80 --ingress external --query properties.configuration.ingress.fqdn
#curl de l'output
#ex: curl https://nginx-container-app.happypond-923e93a4.westeurope.azurecontainerapps.io/
az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --output yaml > app.yaml

#On edite...

az containerapp update --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --yaml app.yaml --output table


#az group delete --name $RESOURCE_GROUP --yes