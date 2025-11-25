resource "databricks_schema" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  catalog_name  = var.config.catalog_name
  name          = var.config.name
  comment       = try(var.config.comment, null)
  properties    = try(var.config.properties, null)
  storage_root  = try(var.config.storage_root, null)
  owner         = try(var.config.owner, null)
  force_destroy = try(var.config.force_destroy, false)
}

# Grants - Assign permissions to principals
resource "databricks_grants" "this" {
  count = try(var.config.enabled, true) && try(var.config.permissions, null) != null ? 1 : 0

  schema = databricks_schema.this[0].id

  dynamic "grant" {
    for_each = try(var.config.permissions, [])
    content {
      principal = try(
        grant.value.principal,
        try(grant.value.service_principal_name, try(grant.value.group_name, try(grant.value.user_name, null)))
      )
      privileges = try(
        grant.value.privileges,
        try([grant.value.permission_level], null)
      )
    }
  }

  depends_on = [databricks_schema.this]
}

