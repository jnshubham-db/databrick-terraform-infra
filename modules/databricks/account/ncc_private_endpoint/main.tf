resource "databricks_mws_ncc_private_endpoint_rule" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  network_connectivity_config_id = var.config.network_connectivity_config_id
  
  resource_id = try(var.config.resource_id, null)
  group_id    = try(var.config.group_id, null)
  
  
  # Common parameters
  domain_names = try(var.config.domain_names, null)
  enabled      = try(var.config.enabled_rule, null)
}

