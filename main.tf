# ============================================================================
# Main Orchestration - Resource Deployment
# ============================================================================

# ============================================================================
# Phase 1: Azure Foundation Resources
# ============================================================================

# Resource Groups
module "resource_groups" {
  source   = "./modules/azure/resource_group"
  for_each = local.enabled_resource_groups

  config = each.value
}

# Access Connectors (Required for Unity Catalog)
module "access_connectors" {
  source   = "./modules/azure/access_connector"
  for_each = local.enabled_access_connectors

  config     = each.value
  depends_on = [module.resource_groups]
}

# Storage Accounts
module "storage_accounts" {
  source   = "./modules/azure/storage_account"
  for_each = local.enabled_storage_accounts

  config     = each.value
  depends_on = [module.access_connectors, module.resource_groups]
}

# Key Vaults
module "key_vaults" {
  source   = "./modules/azure/key_vault"
  for_each = local.enabled_key_vaults

  config     = each.value
  depends_on = [module.resource_groups]
}

# VNets (Standalone - not part of workspace)
module "vnets" {
  source   = "./modules/azure/vnet"
  for_each = local.enabled_vnets

  config     = each.value
  depends_on = [module.resource_groups]
}

# Data Factories
module "data_factories" {
  source   = "./modules/azure/data_factory"
  for_each = local.enabled_data_factories

  config     = each.value
  depends_on = [module.resource_groups, module.vnets]
}

# Virtual Machines
module "vms" {
  source   = "./modules/azure/vm"
  for_each = local.enabled_vms

  config     = each.value
  depends_on = [module.resource_groups, module.vnets]
}

# ============================================================================
# Phase 2: Databricks Workspaces (VNet-Injected with Private Endpoints)
# ============================================================================

module "workspaces" {
  source   = "./modules/azure/workspace_vnet_injected"
  for_each = local.enabled_workspaces

  config     = each.value
  depends_on = [module.resource_groups]
}

# ============================================================================
# Phase 3: Databricks Account-Level Resources
# ============================================================================

# Metastores (Unity Catalog)
module "metastores" {
  source   = "./modules/databricks/account/metastore"
  for_each = local.enabled_metastores

  config = each.value
  depends_on = [
    module.storage_accounts,
    module.access_connectors
  ]

  providers = {
    databricks = databricks.account
  }
}

# Metastore Assignments
module "metastore_assignments" {
  source   = "./modules/databricks/account/metastore_assignment"
  for_each = local.enabled_metastore_assignments

  config = each.value
  depends_on = [
    module.metastores,
    module.workspaces
  ]

  providers = {
    databricks = databricks.account
  }
}

# Network Connectivity Configs
module "ncc_configs" {
  source   = "./modules/databricks/account/ncc"
  for_each = local.enabled_ncc_configs

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.account
  }
}

# NCC Private Endpoints
module "ncc_private_endpoints" {
  source   = "./modules/databricks/account/ncc_private_endpoint"
  for_each = local.enabled_ncc_private_endpoints

  config     = each.value
  depends_on = [module.ncc_configs, module.storage_accounts]

  providers = {
    databricks = databricks.account
  }
}

# Budget Policies
module "budget_policies" {
  source   = "./modules/databricks/account/budget_policy"
  for_each = local.enabled_budget_policies

  config = each.value

  providers = {
    databricks = databricks.account
  }
}

# Service Principals
module "service_principals" {
  source   = "./modules/databricks/account/service_principal"
  for_each = local.enabled_service_principals

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.account
  }
}

# ============================================================================
# Phase 3.5: Workspace Admin Assignment
# ============================================================================
# Automatically adds account-level service principals as workspace admins
# This runs after workspace creation and account SP setup, before workspace resources
# Key: Eliminates manual intervention for SP workspace admin access
#
# Note: Only runs if workspace is configured (host and resource_id are set)

module "workspace_admin_assignments" {
  source = "./modules/databricks/account/workspace_admin_assignment"
  for_each = local.enabled_workspace_admin_assignments

  config = each.value
  depends_on = [
    module.workspaces,
    module.service_principals
  ]

  providers = {
    databricks = databricks.account
  }
}

# ============================================================================
# Phase 4: Databricks Workspace-Level Resources (Unity Catalog Setup)
# ============================================================================

# Storage Credentials
module "storage_credentials" {
  source   = "./modules/databricks/workspace/storage_credential"
  for_each = var.databricks_workspace_host != "" ? local.enabled_storage_credentials : {}

  config = each.value
  depends_on = [
    module.metastores,
    module.metastore_assignments,
    module.access_connectors,
    module.storage_accounts
  ]

  providers = {
    databricks = databricks.workspace
  }
}

# External Locations
module "external_locations" {
  source   = "./modules/databricks/workspace/external_location"
  for_each = var.databricks_workspace_host != "" ? local.enabled_external_locations : {}

  config     = each.value
  depends_on = [module.storage_credentials]

  providers = {
    databricks = databricks.workspace
  }
}

# Catalogs
module "catalogs" {
  source   = "./modules/databricks/workspace/catalog"
  for_each = var.databricks_workspace_host != "" ? local.enabled_catalogs : {}

  config     = each.value
  depends_on = [module.external_locations]

  providers = {
    databricks = databricks.workspace
  }
}

# Schemas
module "schemas" {
  source   = "./modules/databricks/workspace/schema"
  for_each = var.databricks_workspace_host != "" ? local.enabled_schemas : {}

  config     = each.value
  depends_on = [module.catalogs]

  providers = {
    databricks = databricks.workspace
  }
}

# ============================================================================
# Phase 5: Databricks Compute Resources
# ============================================================================

# Cluster Policies
module "cluster_policies" {
  source   = "./modules/databricks/workspace/cluster_policy"
  for_each = var.databricks_workspace_host != "" ? local.enabled_cluster_policies : {}

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.workspace
  }
}

# Clusters
module "clusters" {
  source   = "./modules/databricks/workspace/cluster"
  for_each = var.databricks_workspace_host != "" ? local.enabled_clusters : {}

  config = each.value
  depends_on = [
    module.workspaces,
    module.cluster_policies
  ]

  providers = {
    databricks = databricks.workspace
  }
}

# SQL Warehouses
module "sql_warehouses" {
  source   = "./modules/databricks/workspace/sql_warehouse"
  for_each = var.databricks_workspace_host != "" ? local.enabled_sql_warehouses : {}

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.workspace
  }
}

# ============================================================================
# Phase 6: Databricks Workspace Organization & Observability
# ============================================================================

# Workspace Folders
module "workspace_folders" {
  source   = "./modules/databricks/workspace/workspace_folder"
  for_each = var.databricks_workspace_host != "" ? local.enabled_workspace_folders : {}

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.workspace
  }
}

# Queries
module "queries" {
  source   = "./modules/databricks/workspace/query"
  for_each = var.databricks_workspace_host != "" ? local.enabled_queries : {}

  config = each.value
  depends_on = [
    module.workspaces,
    module.sql_warehouses
  ]

  providers = {
    databricks = databricks.workspace
  }
}

# Alerts
module "alerts" {
  source   = "./modules/databricks/workspace/alert"
  for_each = var.databricks_workspace_host != "" ? local.enabled_alerts : {}

  config = each.value
  depends_on = [
    module.queries
  ]

  providers = {
    databricks = databricks.workspace
  }
}

# Workspace Permissions
module "workspace_permissions" {
  source   = "./modules/databricks/workspace/workspace_permissions"
  for_each = var.databricks_workspace_host != "" ? local.enabled_workspace_permissions : {}

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.workspace
  }
}

