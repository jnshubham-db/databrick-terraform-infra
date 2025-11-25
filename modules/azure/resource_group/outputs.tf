output "id" {
  description = "The ID of the resource group"
  value       = try(azurerm_resource_group.this[0].id, null)
}

output "name" {
  description = "The name of the resource group"
  value       = try(azurerm_resource_group.this[0].name, null)
}

output "location" {
  description = "The location of the resource group"
  value       = try(azurerm_resource_group.this[0].location, null)
}

