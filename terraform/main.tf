terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  azurite_connection_string = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=[STRIPPED 88 bytes];BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
}

# Creamos los 4 containers contra Azurite local
resource "null_resource" "azurite_containers" {
  for_each = toset(["raw", "bronze", "silver", "gold"])

  provisioner "local-exec" {
    command = <<EOT
      az storage container create --name ${each.key} --connection-string '${local.azurite_connection_string}' 2>&1 || \
      python3 -c "
import sys
try:
    from azure.storage.blob import BlobServiceClient
    conn = '${local.azurite_connection_string}'
    client = BlobServiceClient.from_connection_string(conn)
    client.create_container('${each.key}')
    print('Container ${each.key} creado con Python SDK')
except Exception as e:
    print(f'Container ${each.key}: {e}')
"
    EOT
  }
}

output "containers" {
  value = "✅ Azurite containers: raw, bronze, silver, gold en http://127.0.0.1:10000"
}