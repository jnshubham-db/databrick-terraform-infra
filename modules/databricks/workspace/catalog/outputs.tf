output "catalog_id" {
  description = "The ID of the catalog"
  value       = try(databricks_catalog.this[0].id, null)
}

output "name" {
  description = "The name of the catalog"
  value       = try(databricks_catalog.this[0].name, null)
}

