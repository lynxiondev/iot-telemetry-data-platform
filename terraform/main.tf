terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
}

provider "azurerm" {
  features {}
  # Esto hace que apunte a tu Azurite local (el docker que levantaste)
  storage_use_azuread = false
}

# Para local, usamos Azurite. Para prod, solo cambiás el endpoint.
# Esto es exactamente lo que te toman en la DP-203: IaC

resource "azurerm_resource_group" "rg" {
  name     = "rg-lynxion-iot-dev"
  location = "East US"
}

resource "azurerm_storage_account" "sa" {
  name                     = "stlynxioniotdev"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(["raw", "bronze", "silver", "gold"])
  name                  = each.key
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}