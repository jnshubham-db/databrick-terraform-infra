output "warehouse_id" {
  description = "The ID of the SQL warehouse"
  value       = try(databricks_sql_endpoint.this[0].id, null)
}

output "name" {
  description = "The name of the SQL warehouse"
  value       = try(databricks_sql_endpoint.this[0].name, null)
}

output "jdbc_url" {
  description = "JDBC connection URL for the SQL warehouse"
  value       = try(databricks_sql_endpoint.this[0].jdbc_url, null)
  sensitive   = true
}

