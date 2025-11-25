resource "databricks_mws_network_connectivity_config" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name   = var.config.name
  region = var.config.region

  network_connectivity_config_id = try(var.config.network_connectivity_config_id, null)
}

# NCC Binding - Attach NCC to workspace(s)
resource "databricks_mws_ncc_binding" "this" {
  for_each = try(var.config.enabled, true) && try(var.config.workspace_ids, null) != null ? {
    for ws_id in var.config.workspace_ids : tostring(ws_id) => ws_id
  } : {}

  network_connectivity_config_id = databricks_mws_network_connectivity_config.this[0].network_connectivity_config_id
  workspace_id                   = each.value

  depends_on = [databricks_mws_network_connectivity_config.this]
}

