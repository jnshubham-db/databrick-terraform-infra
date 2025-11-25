output "id" {
  description = "The ID of the Data Factory"
  value       = try(azurerm_data_factory.this[0].id, null)
}

output "name" {
  description = "The name of the Data Factory"
  value       = try(azurerm_data_factory.this[0].name, null)
}

output "identity" {
  description = "The managed identity of the Data Factory"
  value       = try(azurerm_data_factory.this[0].identity, null)
}

