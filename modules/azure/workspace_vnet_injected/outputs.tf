output "workspace_id" {
  description = "The Databricks workspace ID"
  value       = try(azurerm_databricks_workspace.this[0].workspace_id, null)
}

output "workspace_url" {
  description = "The workspace URL"
  value       = try(azurerm_databricks_workspace.this[0].workspace_url, null)
}

output "workspace_resource_id" {
  description = "The Azure resource ID of the workspace"
  value       = try(azurerm_databricks_workspace.this[0].id, null)
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = try(azurerm_virtual_network.this[0].id, null)
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = merge(
    {
    public  = try(azurerm_subnet.public[0].id, null)
    private = try(azurerm_subnet.private[0].id, null)
    },
    {
      for k, v in azurerm_subnet.additional : k => v.id
  }
  )
}

output "nsg_id" {
  description = "The ID of the network security group"
  value       = try(azurerm_network_security_group.this[0].id, null)
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone (if created) - privatelink.azuredatabricks.net"
  value       = try(azurerm_private_dns_zone.databricks[0].id, null)
}

output "private_endpoint_ids" {
  description = "IDs of the private endpoints"
  value = {
    workspace = try(azurerm_private_endpoint.workspace[0].id, null)
    browser   = try(azurerm_private_endpoint.browser_auth[0].id, null)
  }
}

