output "id" {
  description = "The ID of the virtual network"
  value       = try(azurerm_virtual_network.this[0].id, null)
}

output "name" {
  description = "The name of the virtual network"
  value       = try(azurerm_virtual_network.this[0].name, null)
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for k, subnet in azurerm_subnet.this : k => subnet.id
  }
}

output "subnet_names" {
  description = "Map of subnet names to their names"
  value = {
    for k, subnet in azurerm_subnet.this : k => subnet.name
  }
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for k, nsg in azurerm_network_security_group.this : k => nsg.id
  }
}

