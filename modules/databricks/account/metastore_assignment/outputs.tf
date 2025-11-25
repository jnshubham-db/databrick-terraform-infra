output "workspace_id" {
  description = "The workspace ID"
  value       = try(databricks_metastore_assignment.this[0].workspace_id, null)
}

output "metastore_id" {
  description = "The metastore ID"
  value       = try(databricks_metastore_assignment.this[0].metastore_id, null)
}

output "default_catalog_name" {
  description = "The default catalog name (deprecated)"
  value       = null # Removed deprecated attribute
}

