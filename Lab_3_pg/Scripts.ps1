$RESOURCE_GROUP="RG-Lab-TME-Postgre"
$LOCATION="francecentral"
$POSTGRESQL_NAME="postgretme2"
$POSTGRESQL_ADMINUSER="adminDB"
$POSTGRESQL_ADMINPASSWORD="Password123_"
$POSTGRESQL_SKUNAME="Standard_B1ms"
$POSTGRESQL_TIER="Burstable"
$POSTGRESQL_VERSION="14"
$POSTGRESQL_STORAGESIZE="32"
$POSTGRESQL_DBNAME="rugby_api"
$ACR_NAME="acrlab3pgtme"
$ACR_SKUNAME="Standard"
$APP_API_NAME="rugby-api"
$APP_API_IMAGE_VERSION="1.0.0"
$APP_FRONT_NAME="rugby-front"
$APP_FRONT_IMAGE_VERSION="1.0.0"
$ENVIRONMENT_NAME="RG-Lab-TME-env2"


az group create --name $RESOURCE_GROUP --location $LOCATION
az group show --resource-group $RESOURCE_GROUP -o table
az postgres flexible-server create --name $POSTGRESQL_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --admin-user $POSTGRESQL_ADMINUSER --admin-password $POSTGRESQL_ADMINPASSWORD --sku-name $POSTGRESQL_SKUNAME --tier $POSTGRESQL_TIER --version $POSTGRESQL_VERSION --storage-size $POSTGRESQL_STORAGESIZE --public-access 0.0.0.0 --yes
az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $POSTGRESQL_NAME -o table
az postgres flexible-server firewall-rule create --name $POSTGRESQL_NAME --resource-group $RESOURCE_GROUP --rule-name allowall --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255
az postgres flexible-server parameter set --resource-group $RESOURCE_GROUP --server-name $POSTGRESQL_NAME --name require_secure_transport --value off
az postgres flexible-server db create --resource-group $RESOURCE_GROUP --server-name $POSTGRESQL_NAME --database-name $POSTGRESQL_DBNAME
az postgres flexible-server db show --resource-group $RESOURCE_GROUP --server-name $POSTGRESQL_NAME --database-name $POSTGRESQL_DBNAME -o table

az postgres flexible-server execute  --admin-password $POSTGRESQL_ADMINPASSWORD  --admin-user $POSTGRESQL_ADMINUSER  --name $POSTGRESQL_NAME  --database-name $POSTGRESQL_DBNAME  --file-path wrkshp-container-apps/Lab_3_pg/DB/create_tables.sql
az containerapp env create  --name $ENVIRONMENT_NAME  --resource-group $RESOURCE_GROUP  --location $LOCATION  --logs-destination none
az containerapp env list --resource-group $RESOURCE_GROUP -o jsonc
az acr create  --resource-group $RESOURCE_GROUP  --name $ACR_NAME  --sku $ACR_SKUNAME  --admin-enabled true
az acr list --resource-group $RESOURCE_GROUP -o table
$compiledName = "$ACR_NAME.azurecr.io/$APP_API_NAME" + ":" + $APP_API_IMAGE_VERSION
az acr build -t $compiledName -r $ACR_NAME wrkshp-container-apps/Lab_3_pg/API
az acr repository list --name $ACR_NAME -o table
$REGISTRY_PASSWORD=$(az acr credential show --name $ACR_NAME -o tsv --query "passwords[0].value")
az containerapp create  --name $APP_API_NAME  --resource-group $RESOURCE_GROUP  --environment $ENVIRONMENT_NAME  --image $compiledName  --registry-username $ACR_NAME  --registry-password $REGISTRY_PASSWORD  --secrets secret-db-host=postgretme2.postgres.database.azure.com secret-db-user=adminDB secret-db-password=Password123_ secret-db-database=rugby_api secret-db-port=5432  --env-vars DB_HOST=secretref:secret-db-host DB_USER=secretref:secret-db-user DB_PASS=secretref:secret-db-password DB_NAME=secretref:secret-db-database DB_PORT=secretref:secret-db-port  --target-port 3000  --ingress external  --registry-server "$ACR_NAME.azurecr.io"  --query configuration.ingress.fqdn

curl https://node-api.orangeflower-f33796bf.francecentral.azurecontainerapps.io/api
curl https://rugby-api.purpleisland-7a4fc55f.westeurope.azurecontainerapps.io/api


REGISTRY_PASSWORD=$(az acr credential show --name $ACR_NAME -o tsv --query "passwords[0].value")
az containerapp create  --name $APP_FRONT_NAME  --resource-group $RESOURCE_GROUP  --environment $ENVIRONMENT_NAME  --image $compiledName  --target-port 80  --ingress external  --registry-server "$ACR_NAME.azurecr.io"  --registry-username $ACR_NAME  --registry-password $REGISTRY_PASSWORD  --query configuration.ingress.fqdn