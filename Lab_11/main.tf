
# create Azure Resource Group
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "Terra-RG" {
  name     = var.resourceGroupName
  location = var.location
}

# create Azure Virtual Network
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "Terra-virtualNetwork" {
  name                = var.virtualNetworkName
  location            = azurerm_resource_group.Terra-RG.location
  resource_group_name = azurerm_resource_group.Terra-RG.name
  address_space       = ["10.0.0.0/16"]
}


# create Azure Subnet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "Terra-Subnet" {
  name                 = var.subnetName
  resource_group_name  = azurerm_resource_group.Terra-RG.name
  virtual_network_name = azurerm_virtual_network.Terra-virtualNetwork.name
  address_prefixes     = ["10.0.0.0/23"]
}

# create Azure Log Analytics Workspace
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "Terra-logsAnalyticsWorkspaceName" {
  name                = var.logsAnalyticsWorkspaceName
  location            = azurerm_resource_group.Terra-RG.location
  resource_group_name = azurerm_resource_group.Terra-RG.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# create Azure Container Apps environment
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment
resource "azurerm_container_app_environment" "Terra-ContainerAppsEnvironment" {
  name                       = var.containerAppsEnvironmentName
  location                   = azurerm_resource_group.Terra-RG.location
  resource_group_name        = azurerm_resource_group.Terra-RG.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.Terra-logsAnalyticsWorkspaceName.id
  infrastructure_subnet_id   = azurerm_subnet.Terra-Subnet.id
}

# Create Azure Storage Account
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "Terra-StorageAccount" {
  name                     = var.storageAccountName
  resource_group_name      = azurerm_resource_group.Terra-RG.name
  location                 = azurerm_resource_group.Terra-RG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a storage share
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share
resource "azurerm_storage_share" "Terra-Storage-Share" {
  name                 = var.shareName
  storage_account_name = azurerm_storage_account.Terra-StorageAccount.name
  quota                = 5
}

# Azure Container Apps environment storage
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment_storage
resource "azurerm_container_app_environment_storage" "Terra-ContainerAppsEnvironmentStorage" {
  name                         = var.containerAppsEnvironmentStorage
  container_app_environment_id = azurerm_container_app_environment.Terra-ContainerAppsEnvironment.id
  account_name                 = azurerm_storage_account.Terra-StorageAccount.name
  share_name                   = azurerm_storage_share.Terra-Storage-Share.name
  access_key                   = azurerm_storage_account.Terra-StorageAccount.primary_access_key
  access_mode                  = "ReadOnly"
}

# Create Azure Container Apps
#cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app
resource "azurerm_container_app" "Terra-ContainerApps" {
  name                         = var.containerAppsName
  container_app_environment_id = azurerm_container_app_environment.Terra-ContainerAppsEnvironment.id
  resource_group_name          = azurerm_resource_group.Terra-RG.name
  revision_mode                = var.revisionMode

  template {
    container {
      name   = "examplecontainerapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}
