resource "databricks_cluster_policy" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name        = var.config.name
  definition  = var.config.definition
  description = try(var.config.description, null)
  policy_family_id = try(var.config.policy_family_id, null)
  policy_family_definition_overrides = try(var.config.policy_family_definition_overrides, null)
  max_clusters_per_user = try(var.config.max_clusters_per_user, null)
}

