resource "azurerm_storage_account" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                            = var.config.name
  resource_group_name             = var.config.resource_group_name
  location                        = var.config.location
  account_tier                    = try(var.config.account_tier, "Standard")
  account_replication_type        = try(var.config.account_replication_type, "LRS")
  is_hns_enabled                  = try(var.config.is_hns_enabled, false)
  public_network_access_enabled   = try(var.config.public_network_access_enabled, false)
  allow_nested_items_to_be_public = try(var.config.allow_nested_items_to_be_public, false)
  min_tls_version                 = try(var.config.min_tls_version, "TLS1_2")
  shared_access_key_enabled       = try(var.config.shared_access_key_enabled, true)

  dynamic "network_rules" {
    for_each = try(var.config.network_rules, null) != null ? [var.config.network_rules] : []

    content {
      default_action             = network_rules.value.default_action
      bypass                     = try(network_rules.value.bypass, ["None"])
      ip_rules                   = try(network_rules.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_rules.value.virtual_network_subnet_ids, [])

      dynamic "private_link_access" {
        for_each = try(var.config.access_connector_id, null) != null ? [var.config.access_connector_id] : []

        content {
          endpoint_resource_id = private_link_access.value
        }
      }
    }
  }

  tags = try(var.config.tags, {})
}

resource "azurerm_storage_container" "this" {
  for_each = try(var.config.enabled, true) ? { for container in try(var.config.containers, []) : container.name => container } : {}

  name                  = each.value.name
  storage_account_id = azurerm_storage_account.this[0].id
  container_access_type = try(each.value.container_access_type, "private")
}

# Role assignments for Access Connector (Unity Catalog)
resource "azurerm_role_assignment" "blob_data_contributor" {
  count = try(var.config.enabled, true) && try(var.config.access_connector_principal_id, null) != null ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.config.access_connector_principal_id
}

resource "azurerm_role_assignment" "queue_data_contributor" {
  count = try(var.config.enabled, true) && try(var.config.access_connector_principal_id, null) != null ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = var.config.access_connector_principal_id
}

resource "azurerm_role_assignment" "eventgrid_contributor" {
  count = try(var.config.enabled, true) && try(var.config.access_connector_principal_id, null) != null ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = var.config.access_connector_principal_id
}

# ============================================================================
# Private DNS Zones for Storage Private Endpoints (Optional - Create if not provided)
# ============================================================================

# Map of subresource types to their DNS zone names
locals {
  dns_zone_names = {
    blob  = "privatelink.blob.core.windows.net"
    dfs   = "privatelink.dfs.core.windows.net"
    file  = "privatelink.file.core.windows.net"
    queue = "privatelink.queue.core.windows.net"
    table = "privatelink.table.core.windows.net"
    web   = "privatelink.web.core.windows.net"
  }

  # Create a map of unique DNS zones needed based on private endpoints
  dns_zones_needed = try(var.config.enabled, true) && try(var.config.create_dns_zones, false) ? {
    for pe in try(var.config.private_endpoints, []) :
    pe.subresource_names[0] => local.dns_zone_names[pe.subresource_names[0]]
    if try(pe.create_dns_zone, true) && contains(keys(local.dns_zone_names), pe.subresource_names[0])
  } : {}
}

# Private DNS Zones for Storage Private Endpoints
resource "azurerm_private_dns_zone" "storage" {
  for_each = local.dns_zones_needed

  name                = each.value
  resource_group_name = try(var.config.dns_zone_resource_group_name, var.config.resource_group_name)

  tags = merge(
    try(var.config.tags, {}),
    {
      purpose = "storage-private-endpoint-${each.key}"
    }
  )
}

# Link DNS Zones to VNet where storage account is accessed
resource "azurerm_private_dns_zone_virtual_network_link" "storage_to_vnet" {
  for_each = local.dns_zones_needed

  name                  = "${var.config.name}-${each.key}-dns-link"
  resource_group_name   = try(var.config.dns_zone_resource_group_name, var.config.resource_group_name)
  private_dns_zone_name = azurerm_private_dns_zone.storage[each.key].name
  virtual_network_id    = var.config.vnet_id
  registration_enabled  = false

  tags = try(var.config.tags, {})
}

# Link DNS Zones to Additional VNets (e.g., hub VNet, other spoke VNets)
resource "azurerm_private_dns_zone_virtual_network_link" "storage_to_additional_vnets" {
  for_each = try(var.config.enabled, true) && try(var.config.create_dns_zones, false) ? {
    for pair in flatten([
      for subresource, zone_name in local.dns_zones_needed : [
        for vnet_id in try(var.config.additional_vnet_links, []) : {
          key           = "${subresource}-${basename(vnet_id)}"
          subresource   = subresource
          zone_name     = zone_name
          vnet_id       = vnet_id
        }
      ]
    ]) : pair.key => pair
  } : {}

  name                  = "${var.config.name}-${each.value.subresource}-dns-link-${basename(each.value.vnet_id)}"
  resource_group_name   = try(var.config.dns_zone_resource_group_name, var.config.resource_group_name)
  private_dns_zone_name = azurerm_private_dns_zone.storage[each.value.subresource].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false

  tags = try(var.config.tags, {})
}

# ============================================================================
# Private Endpoints for Storage Account
# ============================================================================

# Private Endpoints for Storage Account (supports multiple endpoints for different subresources)
resource "azurerm_private_endpoint" "this" {
  for_each = try(var.config.enabled, true) ? { for pe in try(var.config.private_endpoints, []) : pe.name => pe } : {}

  name                = each.value.name
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "${each.value.name}-psc"
    private_connection_resource_id = azurerm_storage_account.this[0].id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = try(var.config.create_dns_zones, false) || try(each.value.private_dns_zone_ids, null) != null ? [1] : []

    content {
      name = "default"
      private_dns_zone_ids = try(var.config.create_dns_zones, false) ? [
        azurerm_private_dns_zone.storage[each.value.subresource_names[0]].id
      ] : each.value.private_dns_zone_ids
    }
  }

  tags = try(var.config.tags, {})

  depends_on = [
    azurerm_private_dns_zone.storage,
    azurerm_private_dns_zone_virtual_network_link.storage_to_vnet
  ]
}

