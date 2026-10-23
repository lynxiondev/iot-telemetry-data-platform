terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-lynxion-dev"
  location = "East US"
}

resource "azurerm_storage_account" "sa" {
  name                     = "stlynxionzwcio"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(["raw", "bronze", "silver", "gold"])
  name                  = each.key
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_iothub" "iot" {
  name                = "iot-lynxion-zwcio"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  min_tls_version     = "1.2"

  sku {
    name     = "F1"
    capacity = 1
  }
}

output "storage_account" {
  value = azurerm_storage_account.sa.name
}
output "resource_group" {
  value = azurerm_resource_group.rg.name
}