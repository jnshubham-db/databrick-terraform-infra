output "service_principal_ids" {
  description = "Map of application IDs to service principal IDs"
  value = {
    for app_id, sp in data.databricks_service_principal.this :
    app_id => sp.id
  }
}

output "permission_assignments" {
  description = "Map of permission assignment IDs"
  value = {
    for app_id, assignment in databricks_mws_permission_assignment.sp_admin :
    app_id => assignment.id
  }
}

output "workspace_id" {
  description = "The workspace ID where permissions were assigned"
  value       = try(var.config.workspace_id, null)
}

