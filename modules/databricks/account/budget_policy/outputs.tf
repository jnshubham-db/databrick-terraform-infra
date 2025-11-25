output "budget_id" {
  description = "The ID of the budget configuration"
  value       = try(databricks_budget.this[0].budget_configuration_id, null)
}

output "display_name" {
  description = "The display name of the budget"
  value       = try(databricks_budget.this[0].display_name, null)
}

