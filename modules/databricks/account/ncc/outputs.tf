output "ncc_id" {
  description = "The ID of the network connectivity config"
  value       = try(databricks_mws_network_connectivity_config.this[0].network_connectivity_config_id, null)
}

output "network_connectivity_config_id" {
  description = "Alias for ncc_id - The ID of the network connectivity config"
  value       = try(databricks_mws_network_connectivity_config.this[0].network_connectivity_config_id, null)
}

output "name" {
  description = "The name of the network connectivity config"
  value       = try(databricks_mws_network_connectivity_config.this[0].name, null)
}

output "region" {
  description = "The region of the network connectivity config"
  value       = try(databricks_mws_network_connectivity_config.this[0].region, null)
}

output "bound_workspace_ids" {
  description = "List of workspace IDs that this NCC is bound to"
  value       = [for binding in databricks_mws_ncc_binding.this : binding.workspace_id]
}

output "binding_ids" {
  description = "Map of workspace IDs to their binding resource IDs"
  value = {
    for k, binding in databricks_mws_ncc_binding.this : k => binding.id
  }
}

