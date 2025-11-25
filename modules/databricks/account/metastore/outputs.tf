output "metastore_id" {
  description = "The ID of the metastore"
  value       = try(databricks_metastore.this[0].id, null)
}

output "name" {
  description = "The name of the metastore"
  value       = try(databricks_metastore.this[0].name, null)
}

output "region" {
  description = "The region of the metastore"
  value       = try(databricks_metastore.this[0].region, null)
}

