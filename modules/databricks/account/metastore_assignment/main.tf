resource "databricks_metastore_assignment" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  metastore_id = var.config.metastore_id
  workspace_id = var.config.workspace_id
}

# Set default catalog using the new recommended resource
resource "databricks_default_namespace_setting" "this" {
  count = try(var.config.enabled, true) && try(var.config.default_catalog_name, null) != null ? 1 : 0

  namespace {
    value = try(var.config.default_catalog_name, "main")
  }

  depends_on = [databricks_metastore_assignment.this]
}

