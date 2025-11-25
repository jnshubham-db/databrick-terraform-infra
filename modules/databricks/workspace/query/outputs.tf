output "query_id" {
  description = "The ID of the SQL query"
  value       = try(databricks_query.this[0].id, null)
}

output "name" {
  description = "The name of the SQL query"
  value       = try(databricks_query.this[0].display_name, null)
}

