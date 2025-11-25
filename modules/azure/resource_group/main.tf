resource "azurerm_resource_group" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name     = var.config.name
  location = var.config.location
  tags     = try(var.config.tags, {})
}

