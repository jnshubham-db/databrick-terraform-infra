resource "databricks_sql_endpoint" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                      = var.config.name
  cluster_size              = var.config.cluster_size
  min_num_clusters          = try(var.config.min_num_clusters, 1)
  max_num_clusters          = try(var.config.max_num_clusters, 1)
  auto_stop_mins            = try(var.config.auto_stop_mins, 120)
  spot_instance_policy      = try(var.config.spot_instance_policy, "COST_OPTIMIZED")
  warehouse_type            = try(var.config.warehouse_type, "PRO")
  enable_photon             = try(var.config.enable_photon, true)
  enable_serverless_compute = try(var.config.enable_serverless_compute, false)

  dynamic "channel" {
    for_each = try(var.config.channel, null) != null ? [var.config.channel] : []

    content {
      name = try(channel.value.name, "CHANNEL_NAME_CURRENT")
    }
  }

  dynamic "tags" {
    for_each = try(var.config.tags, null) != null ? [var.config.tags] : []

    content {
      dynamic "custom_tags" {
        for_each = try(tags.value.custom_tags, [])

        content {
          key   = custom_tags.value.key
          value = custom_tags.value.value
        }
      }
    }
  }
}

# Permissions - Assign permissions to principals
resource "databricks_permissions" "this" {
  count = try(var.config.enabled, true) && try(var.config.permissions, null) != null ? 1 : 0

  sql_endpoint_id = databricks_sql_endpoint.this[0].id

  dynamic "access_control" {
    for_each = try(var.config.permissions, [])
    content {
      group_name             = try(access_control.value.group_name, null)
      user_name              = try(access_control.value.user_name, null)
      service_principal_name = try(access_control.value.service_principal_name, null)
      permission_level       = access_control.value.permission_level
    }
  }

  depends_on = [databricks_sql_endpoint.this]
}

