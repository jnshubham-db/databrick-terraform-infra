output "credential_id" {
  description = "The ID of the storage credential"
  value       = try(databricks_storage_credential.this[0].id, null)
}

output "name" {
  description = "The name of the storage credential"
  value       = try(databricks_storage_credential.this[0].name, null)
}

