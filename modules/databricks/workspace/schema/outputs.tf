output "schema_id" {
  description = "The ID of the schema"
  value       = try(databricks_schema.this[0].id, null)
}

output "name" {
  description = "The name of the schema"
  value       = try(databricks_schema.this[0].name, null)
}

output "full_name" {
  description = "The full name of the schema (catalog.schema)"
  value       = try("${databricks_schema.this[0].catalog_name}.${databricks_schema.this[0].name}", null)
}

