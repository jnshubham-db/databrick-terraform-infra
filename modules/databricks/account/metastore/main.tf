resource "databricks_metastore" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name          = var.config.name
  storage_root  = try(var.config.storage_root, null)
  region        = try(var.config.region, null)
  owner         = try(var.config.owner, null)
  force_destroy = try(var.config.force_destroy, false)

  delta_sharing_scope                             = try(var.config.delta_sharing_scope, null)
  delta_sharing_recipient_token_lifetime_in_seconds = try(var.config.delta_sharing_recipient_token_lifetime_in_seconds, null)
  delta_sharing_organization_name                 = try(var.config.delta_sharing_organization_name, null)
}

