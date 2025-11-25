resource "azurerm_databricks_access_connector" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  resource_group_name = var.config.resource_group_name
  location            = var.config.location

  identity {
    type = "SystemAssigned"
  }

  tags = try(var.config.tags, {})
}

