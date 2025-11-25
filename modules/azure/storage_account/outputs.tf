output "id" {
  description = "The ID of the storage account"
  value       = try(azurerm_storage_account.this[0].id, null)
}

output "name" {
  description = "The name of the storage account"
  value       = try(azurerm_storage_account.this[0].name, null)
}

output "primary_dfs_endpoint" {
  description = "The primary DFS endpoint URL"
  value       = try(azurerm_storage_account.this[0].primary_dfs_endpoint, null)
}

output "primary_blob_endpoint" {
  description = "The primary Blob endpoint URL"
  value       = try(azurerm_storage_account.this[0].primary_blob_endpoint, null)
}

output "primary_dfs_host" {
  description = "The hostname with port if applicable for DFS storage"
  value       = try(azurerm_storage_account.this[0].primary_dfs_host, null)
}

output "container_ids" {
  description = "Map of container names to their resource IDs"
  value = {
    for k, container in azurerm_storage_container.this : k => container.id
  }
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to their resource IDs"
  value = {
    for k, pe in azurerm_private_endpoint.this : k => pe.id
  }
}

output "private_dns_zone_ids" {
  description = "Map of DNS zone subresource types to their resource IDs (if created)"
  value = {
    for k, zone in azurerm_private_dns_zone.storage : k => zone.id
  }
}

