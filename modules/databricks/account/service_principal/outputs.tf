output "sp_id" {
  description = "The Databricks ID of the service principal"
  value       = try(databricks_service_principal.this[0].id, null)
}

output "application_id" {
  description = "The application ID of the service principal"
  value       = try(databricks_service_principal.this[0].application_id, null)
}

output "display_name" {
  description = "The display name of the service principal"
  value       = try(databricks_service_principal.this[0].display_name, null)
}

