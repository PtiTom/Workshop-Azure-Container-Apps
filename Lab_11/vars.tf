variable "location" {
  description = "The Azure Region where all resources should be created."
  type        = string
  default     = "westeurope"
}

variable "resourceGroupName" {
  description = "The name of the resource group in which to create the resources."
  type        = string
  default     = "RG-Lab-11"
}

variable "logsAnalyticsWorkspaceName" {
  description = "The name of the Log Analytics Workspace in which to create the resources."
  type        = string
  default     = "Logs-Lab-11"
}

variable "containerAppsEnvironmentName" {
  description = "The name of the Container Apps Environment in which to create the resources."
  type        = string
  default     = "containerappslab11"
  validation {
    condition     = length(var.containerAppsEnvironmentName) > 3 && length(var.containerAppsEnvironmentName) < 64
    error_message = "The Container Apps Environment name must be between 3 and 64 characters in length."
  }
}

variable "storageAccountName" {
  description = "The name of the Storage Account in which to create the resources."
  type        = string
  default     = "storagelab11stan"
}

variable "shareName" {
  description = "The name of the Storage Share in which to create the resources."
  type        = string
  default     = "share1"
}

variable "containerAppsEnvironmentStorage" {
  description = "The name of the Container Apps Environment Storage in which to create the resources."
  type        = string
  default     = "containerappsstoragelab11"
}

variable "virtualNetworkName" {
  description = "The name of the Virtual Network in which to create the resources."
  type        = string
  default     = "VNet-Lab-11"
}

variable "subnetName" {
  description = "The name of the Subnet in which to create the resources."
  type        = string
  default     = "Subnet-Lab-11"
}


variable "containerAppsName" {
  description = "The name of the Container Apps in which to create the resources."
  type        = string
  default     = "containerapps1"
}

variable "revisionMode" {
    description = "The revision mode of the Container Apps in which to create the resources."
    type        = string
    default     = "Single"
    validation {
        condition     = var.revisionMode == "Single" || var.revisionMode == "Multiple"
        error_message = "The revision mode must be either Single or Multiple."
    }
}