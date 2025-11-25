# ============================================================================
# Outputs - Major Resource Information
# ============================================================================

# ============================================================================
# Resource Groups
# ============================================================================

output "resource_group_ids" {
  description = "Map of resource group names to their IDs"
  value = {
    for k, rg in module.resource_groups : k => rg.id
  }
}

# ============================================================================
# Databricks Workspaces
# ============================================================================

output "workspace_ids" {
  description = "Map of workspace names to their workspace IDs"
  value = {
    for k, ws in module.workspaces : k => ws.workspace_id
  }
}

output "workspace_urls" {
  description = "Map of workspace names to their URLs"
  value = {
    for k, ws in module.workspaces : k => ws.workspace_url
  }
}

output "workspace_resource_ids" {
  description = "Map of workspace names to their Azure resource IDs"
  value = {
    for k, ws in module.workspaces : k => ws.workspace_resource_id
  }
}

# ============================================================================
# Storage Accounts
# ============================================================================

output "storage_account_ids" {
  description = "Map of storage account names to their IDs"
  value = {
    for k, sa in module.storage_accounts : k => sa.id
  }
}

output "storage_account_dfs_endpoints" {
  description = "Map of storage account names to their DFS endpoints"
  value = {
    for k, sa in module.storage_accounts : k => sa.primary_dfs_endpoint
  }
}

# ============================================================================
# Access Connectors
# ============================================================================

output "access_connector_ids" {
  description = "Map of access connector names to their IDs"
  value = {
    for k, ac in module.access_connectors : k => ac.id
  }
}

output "access_connector_principal_ids" {
  description = "Map of access connector names to their managed identity principal IDs"
  value = {
    for k, ac in module.access_connectors : k => ac.identity_principal_id
  }
}

# ============================================================================
# Unity Catalog - Metastores
# ============================================================================

output "metastore_ids" {
  description = "Map of metastore names to their IDs"
  value = {
    for k, ms in module.metastores : k => ms.metastore_id
  }
}

# ============================================================================
# Unity Catalog - Storage Credentials
# ============================================================================

output "storage_credential_ids" {
  description = "Map of storage credential names to their IDs"
  value = {
    for k, sc in module.storage_credentials : k => sc.credential_id
  }
}

# ============================================================================
# Unity Catalog - External Locations
# ============================================================================

output "external_location_ids" {
  description = "Map of external location names to their IDs"
  value = {
    for k, el in module.external_locations : k => el.location_id
  }
}

# ============================================================================
# Unity Catalog - Catalogs
# ============================================================================

output "catalog_ids" {
  description = "Map of catalog names to their IDs"
  value = {
    for k, cat in module.catalogs : k => cat.catalog_id
  }
}

# ============================================================================
# Clusters
# ============================================================================

output "cluster_ids" {
  description = "Map of cluster names to their IDs"
  value = {
    for k, cl in module.clusters : k => cl.cluster_id
  }
}

output "cluster_urls" {
  description = "Map of cluster names to their URLs"
  value = {
    for k, cl in module.clusters : k => cl.cluster_url
  }
}

# ============================================================================
# SQL Warehouses
# ============================================================================

output "sql_warehouse_ids" {
  description = "Map of SQL warehouse names to their IDs"
  value = {
    for k, wh in module.sql_warehouses : k => wh.warehouse_id
  }
}

output "sql_warehouse_jdbc_urls" {
  description = "Map of SQL warehouse names to their JDBC URLs"
  value = {
    for k, wh in module.sql_warehouses : k => wh.jdbc_url
  }
  sensitive = true
}

# ============================================================================
# Key Vaults
# ============================================================================

output "key_vault_ids" {
  description = "Map of Key Vault names to their IDs"
  value = {
    for k, kv in module.key_vaults : k => kv.id
  }
}

output "key_vault_uris" {
  description = "Map of Key Vault names to their URIs"
  value = {
    for k, kv in module.key_vaults : k => kv.vault_uri
  }
}

# ============================================================================
# Workspace Admin Assignments
# ============================================================================

output "workspace_admin_assignments" {
  description = "Workspace admin assignments for account-level service principals (using account-level API)"
  value = {
    for k, v in module.workspace_admin_assignments : k => {
      service_principal_ids  = v.service_principal_ids
      permission_assignments = v.permission_assignments
      workspace_id          = v.workspace_id
    }
  }
}

