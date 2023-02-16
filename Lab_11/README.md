# Lab_11 Déploiement en mode Infra as Code avec Terraform

tags: #azure #azurecontainerapps #iac #terraform #provider

## Objectif:
Déployer un environnement Azure Container Apps et une __révision__ via du code Terraform

Les ressources Azure Container Apps sont disponibles dans le provider azurerm depuis la version 3.43

cf. https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md#3430-february-09-2023 



## Pré-requis sur le poste d'administration
- Un abonnement Azure avec les privilèges d'administration (idéalement owner)
- Un environnement Shell sous Bash
- Azure CLI 2.37 or >: [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) 
- Terraform + le provider azurerm version 3.43 ou ultérieur

Les opérations sont réalisables depuis l'Azure Cloud Shell (Bash Shell) : https://shell.azure.com 


## Terraform workflow 

Aller dans le répertoire ./Lab_11

Modifier le fichier terraform.tfvars et affecter vos valeurs aux différentes variables

Editer les différents fichiers .tf et lire, comprendre le code Terraform

```bash
terraform init
terraform plan
terraform apply
```

Aller prendre un café avec vos amis et collègues

Dans le portail Azure aller vérifier les objets créés. Rechercher la présence d'un resource group MC_...., regarder ce qu'il contient