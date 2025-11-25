resource "azurerm_data_factory" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  location            = var.config.location
  resource_group_name = var.config.resource_group_name

  public_network_enabled          = try(var.config.public_network_enabled, true)
  managed_virtual_network_enabled = try(var.config.managed_virtual_network_enabled, false)

  dynamic "identity" {
    for_each = try(var.config.identity, null) != null ? [var.config.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "github_configuration" {
    for_each = try(var.config.github_configuration, null) != null ? [var.config.github_configuration] : []

    content {
      account_name    = github_configuration.value.account_name
      branch_name     = github_configuration.value.branch_name
      repository_name = github_configuration.value.repository_name
      root_folder     = github_configuration.value.root_folder
      git_url         = try(github_configuration.value.git_url, null)
    }
  }

  dynamic "vsts_configuration" {
    for_each = try(var.config.vsts_configuration, null) != null ? [var.config.vsts_configuration] : []

    content {
      account_name    = vsts_configuration.value.account_name
      branch_name     = vsts_configuration.value.branch_name
      project_name    = vsts_configuration.value.project_name
      repository_name = vsts_configuration.value.repository_name
      root_folder     = vsts_configuration.value.root_folder
      tenant_id       = try(vsts_configuration.value.tenant_id, null)
    }
  }

  tags = try(var.config.tags, {})
}

# Private Endpoint for Data Factory
resource "azurerm_private_endpoint" "this" {
  count = try(var.config.enabled, true) && try(var.config.private_endpoint, null) != null ? 1 : 0

  name                = try(var.config.private_endpoint.name, "${var.config.name}-pe")
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  subnet_id           = var.config.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.config.name}-psc"
    private_connection_resource_id = azurerm_data_factory.this[0].id
    subresource_names              = try(var.config.private_endpoint.subresource_names, ["dataFactory"])
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

