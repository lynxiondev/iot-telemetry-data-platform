output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}
output "containers" {
  value = [for c in azurerm_storage_container.containers : c.name]
} 