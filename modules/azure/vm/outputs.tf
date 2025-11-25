output "id" {
  description = "The ID of the Virtual Machine"
  value       = try(azurerm_linux_virtual_machine.this[0].id, azurerm_windows_virtual_machine.this[0].id, null)
}

output "name" {
  description = "The name of the Virtual Machine"
  value       = try(azurerm_linux_virtual_machine.this[0].name, azurerm_windows_virtual_machine.this[0].name, null)
}

output "private_ip_address" {
  description = "The private IP address of the Virtual Machine"
  value       = try(azurerm_network_interface.this[0].private_ip_address, null)
}

output "network_interface_id" {
  description = "The ID of the network interface"
  value       = try(azurerm_network_interface.this[0].id, null)
}

