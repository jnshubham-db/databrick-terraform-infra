output "policy_id" {
  description = "The ID of the cluster policy"
  value       = try(databricks_cluster_policy.this[0].id, null)
}

output "name" {
  description = "The name of the cluster policy"
  value       = try(databricks_cluster_policy.this[0].name, null)
}

