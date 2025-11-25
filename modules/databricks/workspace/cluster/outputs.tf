output "cluster_id" {
  description = "The ID of the cluster"
  value       = try(databricks_cluster.this[0].id, null)
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = try(databricks_cluster.this[0].cluster_name, null)
}

output "cluster_url" {
  description = "The URL of the cluster"
  value       = try(databricks_cluster.this[0].url, null)
}

