output "id" {
  description = "The ID of the Key Vault"
  value       = try(azurerm_key_vault.this[0].id, null)
}

output "name" {
  description = "The name of the Key Vault"
  value       = try(azurerm_key_vault.this[0].name, null)
}

output "vault_uri" {
  description = "The URI of the Key Vault"
  value       = try(azurerm_key_vault.this[0].vault_uri, null)
}

