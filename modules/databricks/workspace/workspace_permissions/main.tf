data "databricks_group" "admins" {
  count = try(var.config.enabled, true) ? 1 : 0

  display_name = "admins"
}

resource "databricks_service_principal" "this" {
  for_each = try(var.config.enabled, true) ? toset(try(var.config.service_principal_application_ids, [])) : toset([])

  application_id       = each.value
  display_name         = try(var.config.service_principal_names[each.value], "Service Principal ${each.value}")
  allow_cluster_create = try(var.config.allow_cluster_create, true)
  workspace_access     = try(var.config.workspace_access, true)
  databricks_sql_access = try(var.config.databricks_sql_access, true)
}

resource "databricks_group_member" "sp_admin" {
  for_each = try(var.config.enabled, true) && try(var.config.grant_admin_access, false) ? toset(try(var.config.service_principal_application_ids, [])) : toset([])

  group_id  = data.databricks_group.admins[0].id
  member_id = databricks_service_principal.this[each.value].id
}

# Create additional groups
resource "databricks_group" "this" {
  for_each = try(var.config.enabled, true) ? { for group in try(var.config.groups, []) : group.name => group } : {}

  display_name               = each.value.name
  allow_cluster_create       = try(each.value.allow_cluster_create, false)
  allow_instance_pool_create = try(each.value.allow_instance_pool_create, false)
  workspace_access           = try(each.value.workspace_access, true)
  databricks_sql_access      = try(each.value.databricks_sql_access, true)
}

# Add members to groups
resource "databricks_group_member" "this" {
  for_each = try(var.config.enabled, true) ? { for membership in flatten([
    for group_name, members in try(var.config.group_members, {}) : [
      for member in members : {
        group_name = group_name
        member_id  = member
        key        = "${group_name}-${member}"
      }
    ]
  ]) : membership.key => membership } : {}

  group_id  = databricks_group.this[each.value.group_name].id
  member_id = each.value.member_id
}

