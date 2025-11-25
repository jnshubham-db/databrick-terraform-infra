resource "databricks_service_principal" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  application_id       = var.config.application_id
  display_name         = var.config.display_name
  active               = try(var.config.active, true)
  allow_cluster_create = try(var.config.allow_cluster_create, false)
  allow_instance_pool_create = try(var.config.allow_instance_pool_create, false)
  workspace_access     = try(var.config.workspace_access, true)
  databricks_sql_access = try(var.config.databricks_sql_access, true)
  external_id          = try(var.config.external_id, null)
  force                = try(var.config.force, false)
}

resource "databricks_service_principal_role" "this" {
  for_each = try(var.config.enabled, true) ? toset(try(var.config.roles, [])) : toset([])

  service_principal_id = databricks_service_principal.this[0].id
  role                 = each.value
}

