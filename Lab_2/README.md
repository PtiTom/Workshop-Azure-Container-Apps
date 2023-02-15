# Lab_2 Déploiement d’une infrastructure Azure Container Apps plus avancée en Azure CLI

tags: #azure #azurecontainerapps #azurecli #cli 

## Objectif:
L'objectif de ce Lab 2, c'est de construire des images de conteneurs pour une application qui sera déployée une Container App via Azure CLI.

L'application sera disponible en 2 versions (il y aura 2 images de conteneurs distinctes) ce qui permettra de tester les révisions et le trafic splitting dans Azure Container Apps (lors du Lab 4) 


## Pré-requis sur le poste d'administration
- Un abonnement Azure avec les privilèges d'administration (idéalement owner)
- Un environnement Shell sous Bash
- Azure CLI 2.37 or >: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
- Avoir cloné ce repository GitHub

Les opérations sont réalisables depuis l'Azure Cloud Shell (Bash Shell) : https://shell.azure.com --> attention à bien cloner ce repo GitHub dans votre cloud Shell

Attention : l'Azure Cloud Shell est un environnement avec certaines limitations: [https://learn.microsoft.com/en-us/azure/cloud-shell/limitations] (https://learn.microsoft.com/en-us/azure/cloud-shell/limitations)

## Préparation de l'environnement de déploiement des conteneurs

Aller dans le répertoire du Lab2

Se connecter à l'abonnement Azure

```bash
az login
az account list -o table
```

Enregistrer le provider

```bash
az provider register --namespace Microsoft.App
az provider show --namespace Microsoft.App
```

### Affectation des variables  (REMPLACER La valeur de LOG_ANALYTICS_NAME par la votre)

```bash
RESOURCE_GROUP="RG-Lab2"
LOCATION="eastus2"
CONTAINERAPPS_ENVIRONMENT="my-environment"
LOG_ANALYTICS_NAME="stan-workspace-lab"
```

### Création d'un ressource group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION -o table
```

### Création d'un Log Analytics Workspace

Créer un Log Analytics Workspace qui sera utilisé pour les logs et métriques d'Azure Container Apps

```bash
az monitor log-analytics workspace create \
 --resource-group $RESOURCE_GROUP \
 --workspace-name $LOG_ANALYTICS_NAME \
 --location $LOCATION \
 -o jsonc

LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv`

LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY=`az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $LOG_ANALYTICS_NAME --out tsv`
```

### Création d'un environnement
Un environnement dans Azure Container Apps défini la frontière de sécurité autour d'un groupe d'applications en conteneurs.

Les applications déployées dans le même environnement se partagent un même VNet et écrivent dans le même Log Analytics Workspace.

Créer un nouvel environnement : 

```bash
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_PRIMARY_KEY \
  -o jsonc
```

Plus d'informations sur cette commande : https://docs.microsoft.com/en-us/cli/azure/containerapp/env?view=azure-cli-latest#az-containerapp-env-create --> à tester avec availability zones

## Création d'une container app depuis une image exemple dans la Microsoft Container Registry

```bash
CONTAINERAPPS_NAME="stan-container-app"

az containerapp create \
  --name $CONTAINERAPPS_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
  --target-port 80 \
  --ingress 'external' \
  --query properties.configuration.ingress.fqdn \
  -o jsonc
```

Vérification du déploiement

Ouvrir un navigateur Web et saisir le FQDN renvoyé par la commande précédente

## Création d'une container app depuis une image dans une Azure Container Registry

### Création d'une Azure Container Registry

Affecter les variables (REMPLACER La valeur de ACR_NAME par la votre)

```bash
ACR_NAME="stanacr2022"  
ACR_SKU="Basic"
```

Créer une Azure Container Registry

```bash
az acr create \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku $ACR_SKU \
  --location $LOCATION \
  -o table
```


### Build and Push de deux versions d'une application

2 images de conteneurs représentant 2 versions d'une application simple vont être construites à partir d'un Dockerfile. La construction de l'image (docker build), le tagging (docker tag) et l'envoi de l'image à l'ACR (docker push) pourraient être fait sur le poste local mais il y a plus simple : faire le build directement dans l'Azure Container Registry via les ACR Tasks

Plus d'informations sur les ACR Tasks : https://docs.microsoft.com/en-us/azure/container-registry/container-registry-tasks-overview

 API v1:  
    -> Allez dans ./API/v1 et exécuter la commande suivante pour construire une image de conteneur dans l'ACR 

```bash
az acr build -t api/api:1.0.0 -r $ACR_NAME .
```

Plus d'information sur la commande az acr build : https://docs.microsoft.com/en-us/cli/azure/acr?view=azure-cli-latest#az-acr-build

API v2:  
-> Allez dans ./API/v2 et exécuter la commande suivante pour construire une image de conteneur dans l'ACR   

```bash
az acr build -t api/api:2.0.0 -r $ACR_NAME .
```

Vérifier les images poussées dans l'Azure Container Registry (ici avec 2 outputs différents): 

```
az acr repository show --name $ACR_NAME --image api/api:1.0.0 -o table
az acr repository show --name $ACR_NAME --image api/api:2.0.0 -o jsonc
```

### Activation du mode login/password sur Azure Container Registry

Malgré la possibilité d'affecter des managed identities user ou system à Azure Container Apps pour simplifier l'authentification et l'utilisation de services Azure (cf. https://docs.microsoft.com/en-us/azure/container-apps/managed-identity), il demeure une __limitation forte vis à vis de l'Azure Container Registry__ : il n'est pas (encore) possible d'utiliser une managed identity authentifier Azure Container Apps (cf. https://www.thorsten-hans.com/managed-identities-with-azure-container-apps/#:~:text=Assigned%20managed%20identities%20can%E2%80%99t%20be%20used%20to%20pull%20container%20images%20from%20Azure%20Container%20Registry%20(ACR)) et il faut donc (pour l'instant) passer par le combo login/password d'ACR.

Pour l'activer :
```bash
az acr update --name $ACR_NAME \
--resource-group $RESOURCE_GROUP \
--admin-enabled true \
-o jsonc
```

Le login et le mot de passe sont disponibles via la commande :

```bash
az acr credential show --name $ACR_NAME -o jsonc
```

Affecter la variable REGISTRY_PASSWORD 

```bash
REGISTRY_PASSWORD=$(az acr credential show --name $ACR_NAME -o tsv --query "passwords[0].value")
```

### Création de la container app

Une container app va avoir besoin de différents paramètres comme :
- Le mode de révision
- La définition des secrets
- La définition des variables d'environnements
- Le paramétrage des pré requis en termes de CPU ou mémoire vive
- L'activation et la configuration de Dapr
- L'activation d'ingress interne ou externe
- Le nombre minimum et maximum de réplicas ou des règles de scaling

Plus d'informations sur les options possibles lors de la création d'une Azure Container App  : https://docs.microsoft.com/en-us/cli/azure/containerapp?view=azure-cli-latest#az-containerapp-create

Note : ici l'application de démo utilisée écoute sur le port 3000 (cf. le fichier server.js)

```bash
APPLICATION_NAME="node-api"

az containerapp create -n $APPLICATION_NAME \
-g $RESOURCE_GROUP \
--image $ACR_NAME.azurecr.io/api/api:1.0.0 \
--environment $CONTAINERAPPS_ENVIRONMENT \
--ingress external \
--target-port 3000 \
--registry-server $ACR_NAME.azurecr.io \
--registry-username $ACR_NAME \
--registry-password $REGISTRY_PASSWORD \
--revisions-mode multiple \
--cpu "0.75" \
--memory "1.5Gi" \
--min-replicas 2 \
--max-replicas 5 \
--query properties.configuration.ingress.fqdn \
-o jsonc
```

Se connecter dans un navigateur à l'URL renvoyée en sortie.

Le message suivant doit être affiché : 

```bash
{"message":"hello API Bleue"}
```

Voir la configuration faite précédemment

```bash
az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o jsonc
```


## Fin du Lab 2

__Conserver le resource group "RG-Lab2", il servira pour le Lab 4__
