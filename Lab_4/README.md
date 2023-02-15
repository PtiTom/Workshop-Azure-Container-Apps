# Lab_4 Montée de version et traffic splitting d’une application

tags: #azure #azurecontainerapps #azurecli #cli #trafficsplitting #bluegreen #canary

## Objectif:
Le cycle de vie des applications dans Azure Container Apps s’organise autour des __révisions__

L'objectif de ce Lab 4 est de voir comment répartir le trafic réseau entre plusieurs versions (revisions) d'une application.

Les patterns les plus classiques en termes de répartition de trafic étant :
- le Rolling Update
- le vert/bleu (ou noir/rouge chez Netflix)
	- https://martinfowler.com/bliki/BlueGreenDeployment.html
- le A/B testing
	- https://en.wikipedia.org/wiki/A/B_testing
- le canary


## Pré-requis sur le poste d'administration
- Un abonnement Azure avec les privilèges d'administration (idéalement owner)
- Un environnement Shell sous Bash
- Azure CLI 2.37 or >: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 

Les opérations sont réalisables depuis l'Azure Cloud Shell (Bash Shell) : https://shell.azure.com 


## Gestion des révisions
Le support de plusieurs révisions dans Azure Container Apps permet de gérer les versions d'une Container App. Il est possible d'activer ou de désactiver des révisions et de contrôler la quantité (le pourcentage) de trafic réseau envoyée à chaque révision.

La première révision est créée avec le déploiement initial de l'application. Des nouvelles révisions sont créées lors des mises à jour de l'application.

Les changements dans une mise à jour se répartissent dans deux catégories :
1. __Revision-scope__ : quand un changement est fait sur les paramètres __properties.template__ (Revision Suffix, image ou configuration du conteneur, règle de scaling) cela déclenche la création d'une nouvelle révision
2. __Application-scope__ : quand un changement est fait sur la section __properties.configuration__ du template de la ressource Container App, ce changement s'applique à toutes les révisions et aucune nouvelle révision n'est créée

Informations complémentaires :
- https://docs.microsoft.com/en-us/azure/container-apps/revisions-manage?tabs=bash
- https://docs.microsoft.com/en-us/azure/container-apps/azure-resource-manager-api-spec?tabs=arm-template#propertiestemplate
- https://docs.microsoft.com/en-us/azure/container-apps/azure-resource-manager-api-spec?tabs=arm-template#propertiesconfiguration

### Liste des révisions
```bash
RESOURCE_GROUP="RG-Lab2"
APPLICATION_NAME="node-api"

az containerapp revision list \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
-o table
```

Une seule révision est disponible avec 2 réplicas et une répartition du trafic à 100.

Pour plus de détails, utiliser le output en jsonc ou yamlc

```bash
az containerapp revision list \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
-o jsonc
```

## Mise à jour de l'application
Déployer la version 2 de l'application node-api

```bash

ACR_NAME="stanacr2022"
IMAGE_NAME=".azurecr.io/api/api:2.0.0"

az containerapp update \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
--image $ACR_NAME$IMAGE_NAME \
-o jsonc
```

Lister les révisions de l'application node-api

```bash
az containerapp revision list \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
-o table

az containerapp revision list \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
-o jsonc

```

Deux révisions sont disponibles avec pour chacune 2 réplicas et une répartition qui est désormais  à 100% sur la version correspondant à l'API version 2.0.0

Ici l'opération a fait un Rolling Update.

Pour avoir plus de détails sur la nouvelle révision : 

```bash
REVISION_NAME=$(az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o tsv --query "[1].name")

echo $REVISION_NAME

az containerapp revision show \
--name $APPLICATION_NAME \
--revision $REVISION_NAME \
--resource-group $RESOURCE_GROUP \
-o jsonc
```

Se connecter à l'URL de la Container App et vérifier que le message est bien API verte.

### Active Revision mode
il y a 2 mode de révision possible :
- Single : une seule révision active à un instant T
- Multiple : plusieurs révisions actives en simultanées

Ce paramétrage est visible pour la Container App dans le portail Azure dans le panneau __Revision management -> Choose revision mode__

Il est également possible de le retrouver dans la configuration de la Container App :
```bash
az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o jsonc --query properties.configuration
```

## Montée de version 

### En mode blue-green

The new version of the application is deployed next to the existing version. This deployment allows you to restart, warm up, and test the new version independently. After the new version is running, you can switch to it, redirecting any new incoming traffic to it. For the user of the application, the deployment of the new version happens without any visible downtime. There's another advantage to blue/green deployment: if a new deployment doesn't work as expected, you can easily abandon it without affecting the live version.

Se connecter à l'URL de l'application Container App. Le Full Qualified domain name est disponible dans le portail dans le panneau Overview ou via la commande :

```bash
az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn
```

Pour obtenir une URL cliquable dans Windows Terminal ou iTerm2 :

```bash
echo "https://$(az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)"
```

Le message affiché doit être :

```bash
{"message":"hello API Green"}
```

### Ajout d'un label de revision

Les label de revision vont servir pour associer une priorité au traffic.

Affecter le label blue à la première révision (API 1.0.0)
```bash
az containerapp revision label add --label "blue" \
--resource-group $RESOURCE_GROUP \
--revision $(az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o tsv --query "[0].name") \
--name $APPLICATION_NAME \
-o jsonc
```

Affecter le label green à la seconde révision (API 2.0.0)
```bash
az containerapp revision label add --label "green" \
--resource-group $RESOURCE_GROUP \
--revision $(az containerapp revision list --name $APPLICATION_NAME --resource-group $RESOURCE_GROUP -o tsv --query "[1].name") \
--name $APPLICATION_NAME \
-o jsonc
```

### Basculer le traffic d'une révision à l'autre 

Pour jouer avec les paramètres de répartition de traffic, il faut activer la fonctionnalité de ingress.

Celle-ci peut être activée lors de la création de l'Azure Container App ou à postériori via la commande

plus d'informations : https://docs.microsoft.com/en-us/cli/azure/containerapp/ingress?view=azure-cli-latest#az-containerapp-ingress-enable

Afficher les détails de la configuration Ingress actuelle :

```bash
az containerapp ingress show \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
-o jsonc
```

Le résultat de la commande doit inclure le fqdn de la Container App et la répartition du traffic avec 100% sur Latest Revision.

Pour rebasculer tout le traffic sur la version blue (API 1.0.0) :

```bash
az containerapp ingress traffic set \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
--label-weight blue=100 \
-o jsonc
```

Dans un navigateur (ou via curl), se connecter à l'URL de l'Azure Container App

```bash
echo "https://$(az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)"

# Si vous voulez tester en ligne de commande
curl $(echo "https://$(az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)")
```

Le message affiché doit être :
```bash
{"message":"hello API Blue"}
```

Exemple de script plus complet pour un déploiement blue-green avec Azure Container Apps : https://github.com/denniszielke/blue-green-with-containerapps/blob/main/scripts/deploy.sh

### En mode canary

Ici on va splitter le traffic de la manière suivante :
- 80% du traffic sur la version 1.0.0
- 20% du traffic sur la version 2.0.0 (le canary)
```bash
az containerapp ingress traffic set \
--name $APPLICATION_NAME \
--resource-group $RESOURCE_GROUP \
--label-weight blue=80 green=20 \
-o jsonc
```

Tester 20 fois une connexion à l'Azure Container App
```bash 
for ((i=0; i<20; ++i)); do curl $(echo "https://$(az containerapp show -n $APPLICATION_NAME \
-g $RESOURCE_GROUP -o tsv --query properties.configuration.ingress.fqdn)"); done
```

La réponse API Green doit représenter environ une requête sur 5.

## Fin du Lab 4
Supprimer le resource group "RG-Lab2"
```bash
az group delete -n "RG-Lab2" -o jsonc
```

