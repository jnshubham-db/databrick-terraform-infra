output "id" {
  description = "The ID of the role assignment"
  value       = try(azurerm_role_assignment.this[0].id, null)
}

output "role_definition_name" {
  description = "The name of the role definition"
  value       = try(azurerm_role_assignment.this[0].role_definition_name, null)
}

output "principal_id" {
  description = "The principal ID"
  value       = try(azurerm_role_assignment.this[0].principal_id, null)
}

