output "service_principal_ids" {
  description = "Map of application IDs to service principal IDs"
  value = {
    for k, sp in databricks_service_principal.this : k => sp.id
  }
}

output "group_ids" {
  description = "Map of group names to group IDs"
  value = {
    for k, group in databricks_group.this : k => group.id
  }
}

