$RESOURCE_GROUP="RG_Lab_10_Tme"
$ENVIRONMENT_NAME="Lab-10-env-tme"
$LOCATION="francecentral"
$VNET_NAME="Lab-10-vnet-tme"
$PREFIX_VNET="10.0.0.0/16"
$SUBNET_ACA_NAME="aca-Subnet-tme"
$PREFIX_SUBNET_ACA_NAME="10.0.0.0/21"
$SUBNET_VM_NAME="vm-test-Subnet-tme"
$PREFIX_SUBNET_VM_TEST="10.0.8.0/24"
$PUBLIC_IP_VM="PublicIP-VM-tme"
$NSG="NSG-VM-TEST-tme"
$CONTAINER_APP_NAME="nginx-container-app"
$USER_NAME="azureuser"
$PASSWORD_USER="Password123$"
$VM="VM-TEST-tme"

az group create --name $RESOURCE_GROUP --location $LOCATION
az group show --resource-group $RESOURCE_GROUP -o table
az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --location $LOCATION --address-prefix $PREFIX_VNET
az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME -o table
az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_ACA_NAME --address-prefixes $PREFIX_SUBNET_ACA_NAME
az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_ACA_NAME -o table
$INFRASTRUCTURE_SUBNET=(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_ACA_NAME --query "id" -o tsv | tr -d '[:space:]')
echo $INFRASTRUCTURE_SUBNET
az containerapp env create --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --logs-destination none --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET --internal-only
az containerapp env list --resource-group $RESOURCE_GROUP -o jsonc 
az containerapp env list --resource-group $RESOURCE_GROUP -o jsonc| grep provisioningState

#Ne pas continuer tant que vous n'avez pas : "provisioningState": "Succeeded"
$ENVIRONMENT_DEFAULT_DOMAIN=(az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --query properties.defaultDomain --out json | tr -d '"')
$ENVIRONMENT_STATIC_IP=(az containerapp env show --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --query properties.staticIp --out json | tr -d '"')
$VNET_ID=(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query id --out json | tr -d '"')
echo $ENVIRONMENT_DEFAULT_DOMAIN
echo $ENVIRONMENT_STATIC_IP
echo $VNET_ID
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $ENVIRONMENT_DEFAULT_DOMAIN
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --virtual-network $VNET_ID --zone-name $ENVIRONMENT_DEFAULT_DOMAIN -e true
az network private-dns record-set a add-record --resource-group $RESOURCE_GROUP --record-set-name "*" --ipv4-address $ENVIRONMENT_STATIC_IP --zone-name $ENVIRONMENT_DEFAULT_DOMAIN
az containerapp env list --resource-group $RESOURCE_GROUP -o jsonc

#Le "provisioningState" doit être "Succeeded"
#Notez le suffix du "defaultDomain" 
#Un nouveau "Resource group" doit être déployé (ex: MC_NOM_DU_SUFFIX_DEFAULT_DOMAIN_.......) 
#On doit avoir au mois trois "aks-agentpool-......."
#Création de l'Azure Container App:

az containerapp create --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME --image nginx --min-replicas 1 --max-replicas 1 --target-port 80 --ingress external --query properties.configuration.ingress.fqdn
#Observez l'output de l'url
#Essayez de faire un curl sur l'output de l'url

curl https://nginx-container-app.proudglacier-77985e33.westeurope.azurecontainerapps.io/
curl: (6) Could not resolve host: nginx-container-app.proudglacier-77985e33.westeurope.azurecontainerapps.io
Normal, nous sommes dans un environnement "privé", pour nos tests, nous allons déployer une VM dans le subnet "vm-test-Subnet"
Création de la VM de test


az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_VM_NAME --address-prefixes $PREFIX_SUBNET_VM_TEST

az network public-ip create --resource-group $RESOURCE_GROUP --name $PUBLIC_IP_VM --sku Standard

az network nsg create --resource-group $RESOURCE_GROUP --name $NSG

az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG --name Rule_SSH --protocol tcp --priority 1000 --destination-port-range 22 --access allow

az network nic create --resource-group $RESOURCE_GROUP --name Nic001 --vnet-name $VNET_NAME --subnet $SUBNET_VM_NAME --public-ip-address $PUBLIC_IP_VM --network-security-group $NSG

az vm create --resource-group $RESOURCE_GROUP --name $VM --location $LOCATION --nics Nic001 --image UbuntuLTS --admin-username $USER_NAME --admin-password $PASSWORD_USER
Récupérer la "publicIpAddress"
Connectez vous à la VM de test (mdp:Password123!):

ssh azureuser@<PUBLICIP>
Dans la VM de test, refaire un curl de l'URL de l'Azure Container App. Ex:
curl https://nginx-container-app.purplerock-adf3f498.westeurope.azurecontainerapps.io

Cela doit nous retourner:
Welcome to nginx!
If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

For online documentation and support please refer to nginx.org.
Commercial support is available at nginx.com.

Thank you for using nginx.

``` Fin du Lab_10 ``` exit az group delete --resource-group $RESOURCE_GROUP --yes ```