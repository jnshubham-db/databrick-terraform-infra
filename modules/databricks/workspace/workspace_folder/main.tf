resource "databricks_directory" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  path                   = var.config.path
  delete_recursive       = try(var.config.delete_recursive, false)
  object_id              = try(var.config.object_id, null)
}

