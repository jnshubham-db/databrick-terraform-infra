resource "azurerm_role_assignment" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  scope                = var.config.scope
  role_definition_name = var.config.role_definition_name
  principal_id         = var.config.principal_id

  skip_service_principal_aad_check = try(var.config.skip_service_principal_aad_check, false)
}

