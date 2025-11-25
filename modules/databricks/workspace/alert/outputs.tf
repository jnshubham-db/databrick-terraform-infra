output "alert_id" {
  description = "The ID of the alert"
  value       = try(databricks_alert.this[0].id, null)
}

output "name" {
  description = "The name of the alert"
  value       = try(databricks_alert.this[0].display_name, null)
}

output "state" {
  description = "Current state of the alert's trigger status"
  value       = try(databricks_alert.this[0].state, null)
}

output "lifecycle_state" {
  description = "The workspace state of the alert"
  value       = try(databricks_alert.this[0].lifecycle_state, null)
}

