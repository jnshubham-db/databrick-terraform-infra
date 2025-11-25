# ============================================================================
# Workspace Admin Assignment Module (Account-Level API)
# ============================================================================
# Automatically adds account-level service principals as workspace admins
# Uses account-level API (databricks_mws_permission_assignment)
# This eliminates manual intervention and doesn't require workspace access
# ============================================================================

# Get service principal by application ID (account-level)
data "databricks_service_principal" "this" {
  for_each = try(var.config.enabled, true) ? toset(try(var.config.service_principal_application_ids, [])) : toset([])

  application_id = each.value
}

# Assign service principals to workspace with ADMIN permissions (account-level)
resource "databricks_mws_permission_assignment" "sp_admin" {
  for_each = try(var.config.enabled, true) ? toset(try(var.config.service_principal_application_ids, [])) : toset([])

  workspace_id = var.config.workspace_id
  principal_id = data.databricks_service_principal.this[each.value].id
  permissions  = ["ADMIN"]
}

