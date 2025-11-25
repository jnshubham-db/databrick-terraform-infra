resource "databricks_storage_credential" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name          = var.config.name
  metastore_id  = try(var.config.metastore_id, null)
  owner         = try(var.config.owner, null)
  comment       = try(var.config.comment, null)
  read_only     = try(var.config.read_only, false)
  force_destroy = try(var.config.force_destroy, false)
  force_update  = try(var.config.force_update, false)
  skip_validation = try(var.config.skip_validation, false)

  dynamic "azure_managed_identity" {
    for_each = try(var.config.azure_managed_identity, null) != null ? [var.config.azure_managed_identity] : []

    content {
      access_connector_id = azure_managed_identity.value.access_connector_id
    }
  }

  dynamic "azure_service_principal" {
    for_each = try(var.config.azure_service_principal, null) != null ? [var.config.azure_service_principal] : []

    content {
      directory_id   = azure_service_principal.value.directory_id
      application_id = azure_service_principal.value.application_id
      client_secret  = azure_service_principal.value.client_secret
    }
  }

  dynamic "databricks_gcp_service_account" {
    for_each = try(var.config.databricks_gcp_service_account, null) != null ? [var.config.databricks_gcp_service_account] : []

    content {
      email = try(databricks_gcp_service_account.value.email, null)
    }
  }

  dynamic "aws_iam_role" {
    for_each = try(var.config.aws_iam_role, null) != null ? [var.config.aws_iam_role] : []

    content {
      role_arn = aws_iam_role.value.role_arn
    }
  }

  isolation_mode = try(var.config.isolation_mode, null)
}

# Workspace Bindings - Bind storage credential to specific workspace(s)
resource "databricks_workspace_binding" "this" {
  for_each = try(var.config.enabled, true) && try(var.config.workspace_ids, null) != null ? {
    for ws_id in var.config.workspace_ids : tostring(ws_id) => ws_id
  } : {}

  securable_name = databricks_storage_credential.this[0].name
  securable_type = "storage_credential"
  workspace_id   = each.value
  binding_type   = try(var.config.binding_type, "BINDING_TYPE_READ_WRITE")

  depends_on = [databricks_storage_credential.this]
}

# Grants - Assign permissions to principals
resource "databricks_grants" "this" {
  count = try(var.config.enabled, true) && try(var.config.permissions, null) != null ? 1 : 0

  storage_credential = databricks_storage_credential.this[0].id

  dynamic "grant" {
    for_each = try(var.config.permissions, [])
    content {
      principal = try(
        grant.value.principal,
        try(grant.value.service_principal_name, try(grant.value.group_name, try(grant.value.user_name, null)))
      )
      privileges = try(
        grant.value.privileges,
        try([grant.value.permission_level], null)
      )
    }
  }

  depends_on = [databricks_storage_credential.this, databricks_workspace_binding.this]
}

