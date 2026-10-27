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

  backend "azurerm" {
    resource_group_name  = "rg-lynxion-dev"
    storage_account_name = "stlynxionzwcio"
    container_name       = "tfstate"
    key                = "terraform.tfstate"
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
  for_each              = toset(["raw", "bronze", "silver", "gold", "tfstate"])
  name                  = each.key
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_iothub" "iot" {
  name                = "iot-lynxion-zwcio"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  min_tls_version     = "1.2"

  identity {
    type = "SystemAssigned"
  }

  sku {
    name     = "F1"
    capacity = 1
  }
}

# Endpoint bien hecho con iothub_id 
resource "azurerm_iothub_endpoint_storage_container" "raw_streaming" {
  resource_group_name = azurerm_resource_group.rg.name
  iothub_id           = azurerm_iothub.iot.id
  name                = "raw-streaming-endpoint"
  container_name      = "raw"
  connection_string   = azurerm_storage_account.sa.primary_blob_connection_string
  file_name_format    = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  batch_frequency_in_seconds = 60
  max_chunk_size_in_bytes    = 10485760
  encoding = "JSON"
}

# Route bien hecha con iothub_name 
resource "azurerm_iothub_route" "streaming_route" {
  resource_group_name = azurerm_resource_group.rg.name
  iothub_name         = azurerm_iothub.iot.name
  name                = "telemetry-to-raw"
  source              = "DeviceMessages"
  condition           = "true"
  endpoint_names      = [azurerm_iothub_endpoint_storage_container.raw_streaming.name]
  enabled             = true
}

output "storage_account" {
  value = azurerm_storage_account.sa.name
}
output "resource_group" {
  value = azurerm_resource_group.rg.name
} 