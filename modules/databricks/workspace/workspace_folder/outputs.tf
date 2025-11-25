output "path" {
  description = "The path of the workspace folder"
  value       = try(databricks_directory.this[0].path, null)
}

output "object_id" {
  description = "The object ID of the workspace folder"
  value       = try(databricks_directory.this[0].object_id, null)
}

