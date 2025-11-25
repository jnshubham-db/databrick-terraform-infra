resource "azurerm_virtual_network" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  resource_group_name = var.config.resource_group_name
  location            = var.config.location
  address_space       = var.config.address_space
  tags                = try(var.config.tags, {})
}

resource "azurerm_subnet" "this" {
  for_each = try(var.config.enabled, true) ? { for subnet in try(var.config.subnets, []) : subnet.name => subnet } : {}

  name                 = each.value.name
  resource_group_name  = var.config.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = try(each.value.delegations, [])

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = try(delegation.value.service_delegation.actions, null)
      }
    }
  }

  service_endpoints                             = try(each.value.service_endpoints, null)
  private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, null)
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, null)
}

resource "azurerm_network_security_group" "this" {
  for_each = try(var.config.enabled, true) && try(var.config.network_security_groups, null) != null ? var.config.network_security_groups : {}

  name                = each.value.name
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  tags                = try(var.config.tags, {})

  dynamic "security_rule" {
    for_each = try(each.value.security_rules, [])

    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = try(security_rule.value.source_port_range, null)
      source_port_ranges         = try(security_rule.value.source_port_ranges, null)
      destination_port_range     = try(security_rule.value.destination_port_range, null)
      destination_port_ranges    = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix      = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes    = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix = try(security_rule.value.destination_address_prefix, null)
      destination_address_prefixes = try(security_rule.value.destination_address_prefixes, null)
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = try(var.config.enabled, true) && try(var.config.nsg_associations, null) != null ? var.config.nsg_associations : {}

  subnet_id                 = azurerm_subnet.this[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_name].id
}

