# VNet for Databricks Workspace
resource "azurerm_virtual_network" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.vnet_config.name
  resource_group_name = var.config.resource_group_name
  location            = var.config.location
  address_space       = var.config.vnet_config.address_space

  tags = try(var.config.tags, {})
}

# Public Subnet for Databricks
resource "azurerm_subnet" "public" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                 = var.config.vnet_config.public_subnet_name
  resource_group_name  = var.config.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.config.vnet_config.public_subnet_cidr]

  delegation {
    name = "databricks-delegation-public"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# Private Subnet for Databricks
resource "azurerm_subnet" "private" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                 = var.config.vnet_config.private_subnet_name
  resource_group_name  = var.config.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.config.vnet_config.private_subnet_cidr]

  delegation {
    name = "databricks-delegation-private"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# Additional Subnets (Optional - for other services like private endpoints, VMs, etc.)
resource "azurerm_subnet" "additional" {
  for_each = try(var.config.enabled, true) ? {
    for idx, subnet in try(var.config.vnet_config.additional_subnets, []) : subnet.name => subnet
  } : {}

  name                 = each.value.name
  resource_group_name  = var.config.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = each.value.address_prefixes

  # Optional: Service endpoints
  service_endpoints = try(each.value.service_endpoints, null)

  # Optional: Private endpoint network policies
  private_endpoint_network_policies = try(each.value.private_endpoint_network_policies, "Disabled")

  # Optional: Delegations for specific services
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
}

# Network Security Group for Databricks
resource "azurerm_network_security_group" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = try(var.config.vnet_config.nsg_name, "${var.config.workspace_name}-nsg")
  location            = var.config.location
  resource_group_name = var.config.resource_group_name

  tags = try(var.config.tags, {})
}

# NSG Association for Public Subnet
resource "azurerm_subnet_network_security_group_association" "public" {
  count = try(var.config.enabled, true) ? 1 : 0

  subnet_id                 = azurerm_subnet.public[0].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

# NSG Association for Private Subnet
resource "azurerm_subnet_network_security_group_association" "private" {
  count = try(var.config.enabled, true) ? 1 : 0

  subnet_id                 = azurerm_subnet.private[0].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

# Databricks Workspace with VNet Injection
resource "azurerm_databricks_workspace" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                        = var.config.workspace_name
  resource_group_name         = var.config.resource_group_name
  location                    = var.config.location
  sku                         = try(var.config.sku, "premium")
  managed_resource_group_name = try(var.config.managed_resource_group_name, "${var.config.workspace_name}-managed-rg")

  public_network_access_enabled         = try(var.config.public_network_access_enabled, false)
  network_security_group_rules_required = try(var.config.network_security_group_rules_required, "NoAzureDatabricksRules")

  custom_parameters {
    no_public_ip                                         = try(var.config.no_public_ip, true)
    virtual_network_id                                   = azurerm_virtual_network.this[0].id
    public_subnet_name                                   = azurerm_subnet.public[0].name
    private_subnet_name                                  = azurerm_subnet.private[0].name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public[0].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private[0].id
  }

  tags = try(var.config.tags, {})

  depends_on = [
    azurerm_subnet_network_security_group_association.public,
    azurerm_subnet_network_security_group_association.private
  ]
}

# ============================================================================
# Private DNS Zone (Optional - Create if not provided)
# ============================================================================

# Private DNS Zone for Databricks Private Link
# Both workspace (databricks_ui_api) and browser (browser_authentication) 
# private endpoints use the SAME DNS zone: privatelink.azuredatabricks.net
# Reference: https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/private-link-standard
resource "azurerm_private_dns_zone" "databricks" {
  count = try(var.config.enabled, true) && try(var.config.private_endpoints.enabled, false) && try(var.config.private_endpoints.create_dns_zones, false) ? 1 : 0

  name                = "privatelink.azuredatabricks.net"
  resource_group_name = try(var.config.private_endpoints.dns_zone_resource_group_name, var.config.resource_group_name)

  tags = merge(
    try(var.config.tags, {}),
    {
      purpose = "databricks-private-link"
    }
  )
}

# Link DNS Zone to Workspace VNet
resource "azurerm_private_dns_zone_virtual_network_link" "databricks_to_vnet" {
  count = try(var.config.enabled, true) && try(var.config.private_endpoints.enabled, false) && try(var.config.private_endpoints.create_dns_zones, false) ? 1 : 0

  name                  = "${var.config.workspace_name}-databricks-dns-link"
  resource_group_name   = try(var.config.private_endpoints.dns_zone_resource_group_name, var.config.resource_group_name)
  private_dns_zone_name = azurerm_private_dns_zone.databricks[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false

  tags = try(var.config.tags, {})
}

# Link DNS Zone to Additional VNets (e.g., hub VNet, user VNets)
resource "azurerm_private_dns_zone_virtual_network_link" "databricks_to_additional_vnets" {
  for_each = try(var.config.enabled, true) && try(var.config.private_endpoints.enabled, false) && try(var.config.private_endpoints.create_dns_zones, false) ? toset(try(var.config.private_endpoints.additional_vnet_links, [])) : toset([])

  name                  = "${var.config.workspace_name}-databricks-dns-link-${basename(each.value)}"
  resource_group_name   = try(var.config.private_endpoints.dns_zone_resource_group_name, var.config.resource_group_name)
  private_dns_zone_name = azurerm_private_dns_zone.databricks[0].name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = try(var.config.tags, {})
}

# ============================================================================
# Private Endpoints
# ============================================================================

# Private Endpoint for Databricks Workspace (Browser Authentication)
resource "azurerm_private_endpoint" "browser_auth" {
  count = try(var.config.enabled, true) && try(var.config.private_endpoints.enabled, false) ? 1 : 0

  name                = "${var.config.workspace_name}-browser-pe"
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  # Support multiple ways to specify subnet:
  # 1. browser_subnet_id - full resource ID (can be external subnet)
  # 2. use_additional_subnets=true + browser_subnet_name - name from additional_subnets
  # 3. subnet_id - fallback shared subnet
  subnet_id = try(
    var.config.private_endpoints.browser_subnet_id,
    try(var.config.private_endpoints.use_additional_subnets, false) && try(var.config.private_endpoints.browser_subnet_name, null) != null ? azurerm_subnet.additional[var.config.private_endpoints.browser_subnet_name].id : null,
    var.config.private_endpoints.subnet_id
  )

  private_service_connection {
    name                           = "${var.config.workspace_name}-browser-psc"
    private_connection_resource_id = azurerm_databricks_workspace.this[0].id
    subresource_names              = ["browser_authentication"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = try(var.config.private_endpoints.create_dns_zones, false) || try(var.config.private_endpoints.private_dns_zone_id, null) != null ? [1] : []

    content {
      name = "default"
      private_dns_zone_ids = [
        try(var.config.private_endpoints.create_dns_zones, false) ? azurerm_private_dns_zone.databricks[0].id : var.config.private_endpoints.private_dns_zone_id
      ]
    }
  }

  tags = try(var.config.tags, {})

  depends_on = [
    azurerm_private_dns_zone.databricks,
    azurerm_private_dns_zone_virtual_network_link.databricks_to_vnet
  ]
}

# Private Endpoint for Databricks Workspace (Workspace)
resource "azurerm_private_endpoint" "workspace" {
  count = try(var.config.enabled, true) && try(var.config.private_endpoints.enabled, false) ? 1 : 0

  name                = "${var.config.workspace_name}-workspace-pe"
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  # Support multiple ways to specify subnet:
  # 1. workspace_subnet_id - full resource ID (can be external subnet)
  # 2. use_additional_subnets=true + workspace_subnet_name - name from additional_subnets
  # 3. subnet_id - fallback shared subnet
  subnet_id = try(
    var.config.private_endpoints.workspace_subnet_id,
    try(var.config.private_endpoints.use_additional_subnets, false) && try(var.config.private_endpoints.workspace_subnet_name, null) != null ? azurerm_subnet.additional[var.config.private_endpoints.workspace_subnet_name].id : null,
    var.config.private_endpoints.subnet_id
  )

  private_service_connection {
    name                           = "${var.config.workspace_name}-workspace-psc"
    private_connection_resource_id = azurerm_databricks_workspace.this[0].id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = try(var.config.private_endpoints.create_dns_zones, false) || try(var.config.private_endpoints.private_dns_zone_id, null) != null ? [1] : []

    content {
      name = "default"
      private_dns_zone_ids = [
        try(var.config.private_endpoints.create_dns_zones, false) ? azurerm_private_dns_zone.databricks[0].id : var.config.private_endpoints.private_dns_zone_id
      ]
    }
  }

  tags = try(var.config.tags, {})

  depends_on = [
    azurerm_private_dns_zone.databricks,
    azurerm_private_dns_zone_virtual_network_link.databricks_to_vnet,
    azurerm_private_endpoint.browser_auth  # Prevent concurrent workspace updates
  ]
}

