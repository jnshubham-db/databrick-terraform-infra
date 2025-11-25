output "location_id" {
  description = "The ID of the external location"
  value       = try(databricks_external_location.this[0].id, null)
}

output "name" {
  description = "The name of the external location"
  value       = try(databricks_external_location.this[0].name, null)
}

output "url" {
  description = "The URL of the external location"
  value       = try(databricks_external_location.this[0].url, null)
}

