output "id" {
  description = "The ID of the Databricks access connector"
  value       = try(azurerm_databricks_access_connector.this[0].id, null)
}

output "identity_principal_id" {
  description = "The principal ID of the system-assigned managed identity"
  value       = try(azurerm_databricks_access_connector.this[0].identity[0].principal_id, null)
}

output "principal_id" {
  description = "Alias for identity_principal_id - The principal ID of the system-assigned managed identity"
  value       = try(azurerm_databricks_access_connector.this[0].identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The tenant ID of the system-assigned managed identity"
  value       = try(azurerm_databricks_access_connector.this[0].identity[0].tenant_id, null)
}

