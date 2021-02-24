terraform {
  backend "azurerm" {
  }
  required_version = ">= 0.14"
}

provider "azurerm" {
  version                     = ">= 2.45.0"
  skip_provider_registration  = true
  skip_credentials_validation = true
  features {}
}

provider "random" {
  version = ">= 2.2.1"
}

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "primary" {
}

# Azure Resource Group used for all resources (per Site)
resource "azurerm_resource_group" "deployment" {
  name     = var.resource_group
  location = var.location
}

# Random Pet Name (based on Resource Group Name)
resource "random_pet" "deployment" {
  separator = ""
  length    = 2
  prefix    = ""
  keepers = {
    azurerm_resource_group_location = azurerm_resource_group.deployment.location
    azurerm_resource_group_name     = azurerm_resource_group.deployment.name
  }
}