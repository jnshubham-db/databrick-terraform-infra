data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                       = var.config.name
  location                   = var.config.location
  resource_group_name        = var.config.resource_group_name
  tenant_id                  = try(var.config.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name                   = try(var.config.sku_name, "standard")
  soft_delete_retention_days = try(var.config.soft_delete_retention_days, 7)
  purge_protection_enabled   = try(var.config.purge_protection_enabled, false)

  enabled_for_disk_encryption     = try(var.config.enabled_for_disk_encryption, false)
  enabled_for_deployment          = try(var.config.enabled_for_deployment, false)
  enabled_for_template_deployment = try(var.config.enabled_for_template_deployment, false)
  enable_rbac_authorization       = try(var.config.enable_rbac_authorization, false)

  public_network_access_enabled = try(var.config.public_network_access_enabled, true)

  dynamic "network_acls" {
    for_each = try(var.config.network_acls, null) != null ? [var.config.network_acls] : []

    content {
      default_action             = network_acls.value.default_action
      bypass                     = try(network_acls.value.bypass, "AzureServices")
      ip_rules                   = try(network_acls.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_acls.value.virtual_network_subnet_ids, [])
    }
  }

  tags = try(var.config.tags, {})
}

resource "azurerm_key_vault_access_policy" "this" {
  for_each = try(var.config.enabled, true) ? { for idx, policy in try(var.config.access_policies, []) : idx => policy } : {}

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = try(each.value.tenant_id, data.azurerm_client_config.current.tenant_id)
  object_id    = each.value.object_id

  key_permissions         = try(each.value.key_permissions, [])
  secret_permissions      = try(each.value.secret_permissions, [])
  certificate_permissions = try(each.value.certificate_permissions, [])
  storage_permissions     = try(each.value.storage_permissions, [])
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "this" {
  count = try(var.config.enabled, true) && try(var.config.private_endpoint, null) != null ? 1 : 0

  name                = try(var.config.private_endpoint.name, "${var.config.name}-pe")
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  subnet_id           = var.config.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.config.name}-psc"
    private_connection_resource_id = azurerm_key_vault.this[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = try(var.config.private_endpoint.private_dns_zone_ids, null) != null ? [1] : []

    content {
      name                 = "default"
      private_dns_zone_ids = var.config.private_endpoint.private_dns_zone_ids
    }
  }

  tags = try(var.config.tags, {})
}

