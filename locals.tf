locals {
  # Resource Groups
  resource_groups = {
    for f in try(fileset("${path.module}/resources/azure/resource_groups", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/resource_groups/${f}"))
  }
  all_resource_groups = merge(local.resource_groups, var.resource_groups)
  enabled_resource_groups = {
    for k, v in local.all_resource_groups :
    k => v if try(v.enabled, true)
  }

  # Workspaces (VNet-Injected)
  workspaces = {
    for f in try(fileset("${path.module}/resources/azure/workspaces", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/workspaces/${f}"))
  }
  all_workspaces = merge(local.workspaces, var.workspaces)
  enabled_workspaces = {
    for k, v in local.all_workspaces :
    k => v if try(v.enabled, true)
  }

  # Storage Accounts
  storage_accounts_raw = {
    for f in try(fileset("${path.module}/resources/azure/storage_accounts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/storage_accounts/${f}"))
  }
  
  # Process storage accounts to resolve dynamic references
  storage_accounts = {
    for k, v in local.storage_accounts_raw : k => merge(v, {
      # Resolve access_connector_id if it's a template string
      access_connector_id = try(
        length(regexall("^\\$\\{module\\.access_connectors\\[\"([^\"]+)\"\\]\\.id\\}$", v.access_connector_id)) > 0 ?
        module.access_connectors[regex("^\\$\\{module\\.access_connectors\\[\"([^\"]+)\"\\]\\.id\\}$", v.access_connector_id)[0]].id :
        v.access_connector_id,
        v.access_connector_id
      )
      
      # Resolve access_connector_principal_id if it's a template string
      access_connector_principal_id = try(
        length(regexall("^\\$\\{module\\.access_connectors\\[\"([^\"]+)\"\\]\\.principal_id\\}$", v.access_connector_principal_id)) > 0 ?
        module.access_connectors[regex("^\\$\\{module\\.access_connectors\\[\"([^\"]+)\"\\]\\.principal_id\\}$", v.access_connector_principal_id)[0]].principal_id :
        v.access_connector_principal_id,
        v.access_connector_principal_id
      )
      
      # Resolve vnet_id if it's a template string
      vnet_id = try(
        length(regexall("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.vnet_id\\}$", v.vnet_id)) > 0 ?
        module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.vnet_id\\}$", v.vnet_id)[0]].vnet_id :
        v.vnet_id,
        v.vnet_id
      )
      
      # Resolve network_rules.virtual_network_subnet_ids
      network_rules = try(v.network_rules, null) != null ? merge(v.network_rules, {
        virtual_network_subnet_ids = try([
          for subnet_ref in v.network_rules.virtual_network_subnet_ids :
          length(regexall("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.subnet_ids\\[\"([^\"]+)\"\\]\\}$", subnet_ref)) > 0 ?
          module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.subnet_ids\\[\"([^\"]+)\"\\]\\}$", subnet_ref)[0]].subnet_ids[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.subnet_ids\\[\"([^\"]+)\"\\]\\}$", subnet_ref)[1]] :
          subnet_ref
        ], [])
      }) : null
      
      # Resolve private_endpoints subnet_ids
      private_endpoints = try([
        for pe in v.private_endpoints : merge(pe, {
          subnet_id = try(
            length(regexall("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.subnet_ids\\[\"([^\"]+)\"\\]\\}$", pe.subnet_id)) > 0 ?
            module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.subnet_ids\\[\"([^\"]+)\"\\]\\}$", pe.subnet_id)[0]].subnet_ids[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.subnet_ids\\[\"([^\"]+)\"\\]\\}$", pe.subnet_id)[1]] :
            pe.subnet_id,
            pe.subnet_id
          )
        })
      ], [])
    })
  }
  
  all_storage_accounts = merge(local.storage_accounts, var.storage_accounts)
  enabled_storage_accounts = {
    for k, v in local.all_storage_accounts :
    k => v if try(v.enabled, true)
  }

  # Key Vaults
  key_vaults = {
    for f in try(fileset("${path.module}/resources/azure/key_vaults", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/key_vaults/${f}"))
  }
  all_key_vaults = merge(local.key_vaults, var.key_vaults)
  enabled_key_vaults = {
    for k, v in local.all_key_vaults :
    k => v if try(v.enabled, true)
  }

  # Data Factories
  data_factories = {
    for f in try(fileset("${path.module}/resources/azure/data_factories", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/data_factories/${f}"))
  }
  all_data_factories = merge(local.data_factories, var.data_factories)
  enabled_data_factories = {
    for k, v in local.all_data_factories :
    k => v if try(v.enabled, true)
  }

  # Virtual Machines
  vms = {
    for f in try(fileset("${path.module}/resources/azure/vms", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/vms/${f}"))
  }
  all_vms = merge(local.vms, var.vms)
  enabled_vms = {
    for k, v in local.all_vms :
    k => v if try(v.enabled, true)
  }

  # VNets
  vnets = {
    for f in try(fileset("${path.module}/resources/azure/vnets", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/vnets/${f}"))
  }
  all_vnets = merge(local.vnets, var.vnets)
  enabled_vnets = {
    for k, v in local.all_vnets :
    k => v if try(v.enabled, true)
  }

  # Access Connectors
  access_connectors = {
    for f in try(fileset("${path.module}/resources/azure/access_connectors", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/access_connectors/${f}"))
  }
  all_access_connectors = merge(local.access_connectors, var.access_connectors)
  enabled_access_connectors = {
    for k, v in local.all_access_connectors :
    k => v if try(v.enabled, true)
  }

  # =========================================================================
  # Databricks Account Resources
  # =========================================================================

  # Metastores
  metastores = {
    for f in try(fileset("${path.module}/resources/databricks/account/metastores", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/metastores/${f}"))
  }
  all_metastores = merge(local.metastores, var.metastores)
  enabled_metastores = {
    for k, v in local.all_metastores :
    k => v if try(v.enabled, true)
  }

  # Metastore Assignments
  metastore_assignments_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/metastore_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/metastore_assignments/${f}"))
  }
  
  # Process metastore assignments to resolve dynamic references
  metastore_assignments = {
    for k, v in local.metastore_assignments_raw : k => merge(v, {
      # Resolve workspace_id if it's a template string
      workspace_id = try(
        length(regexall("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", v.workspace_id)) > 0 ?
        module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", v.workspace_id)[0]].workspace_id :
        v.workspace_id,
        v.workspace_id
      )
      
      # Resolve metastore_id if it's a template string
      metastore_id = try(
        length(regexall("^\\$\\{module\\.metastores\\[\"([^\"]+)\"\\]\\.metastore_id\\}$", v.metastore_id)) > 0 ?
        module.metastores[regex("^\\$\\{module\\.metastores\\[\"([^\"]+)\"\\]\\.metastore_id\\}$", v.metastore_id)[0]].metastore_id :
        v.metastore_id,
        v.metastore_id
      )
    })
  }
  
  all_metastore_assignments = merge(local.metastore_assignments, var.metastore_assignments)
  enabled_metastore_assignments = {
    for k, v in local.all_metastore_assignments :
    k => v if try(v.enabled, true)
  }

  # Budget Policies
  budget_policies_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/budget_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/budget_policies/${f}"))
  }
  
  # Process budget policies to resolve dynamic workspace_id references in filter
  budget_policies = {
    for k, v in local.budget_policies_raw : k => merge(v, {
      # Resolve workspace_id values in filter if they're template strings
      filter = try(v.filter, null) != null ? merge(v.filter, {
        workspace_id = try(v.filter.workspace_id, null) != null ? merge(v.filter.workspace_id, {
          values = try([
            for ws_ref in v.filter.workspace_id.values :
            length(regexall("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)) > 0 ?
            module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)[0]].workspace_id :
            ws_ref
          ], v.filter.workspace_id.values)
        }) : null
      }) : null
    })
  }
  
  all_budget_policies = merge(local.budget_policies, var.budget_policies)
  enabled_budget_policies = {
    for k, v in local.all_budget_policies :
    k => v if try(v.enabled, true)
  }

  # NCC (Network Connectivity Configs)
  ncc_configs_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/ncc", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/ncc/${f}"))
  }
  
  # Process NCC configs to resolve dynamic workspace_ids references
  ncc_configs = {
    for k, v in local.ncc_configs_raw : k => merge(v, {
      # Resolve workspace_ids array if it contains template strings
      workspace_ids = try(v.workspace_ids, null) != null ? [
        for ws_ref in v.workspace_ids :
        try(
          can(regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)) ?
          module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)[0]].workspace_id :
          ws_ref,
          ws_ref
        )
      ] : null
    })
  }
  
  all_ncc_configs = merge(local.ncc_configs, var.ncc_configs)
  enabled_ncc_configs = {
    for k, v in local.all_ncc_configs :
    k => v if try(v.enabled, true)
  }

  # NCC Private Endpoints
  ncc_private_endpoints_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/ncc_private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/ncc_private_endpoints/${f}"))
  }
  
  # Process NCC private endpoints to resolve dynamic references
  ncc_private_endpoints = {
    for k, v in local.ncc_private_endpoints_raw : k => merge(v, {
      # Resolve network_connectivity_config_id
      network_connectivity_config_id = try(
        can(regex("^\\$\\{module\\.ncc_configs\\[\"([^\"]+)\"\\]\\.network_connectivity_config_id\\}$", v.network_connectivity_config_id)) ?
        module.ncc_configs[regex("^\\$\\{module\\.ncc_configs\\[\"([^\"]+)\"\\]\\.network_connectivity_config_id\\}$", v.network_connectivity_config_id)[0]].network_connectivity_config_id :
        v.network_connectivity_config_id,
        v.network_connectivity_config_id
      )
      # Resolve resource_id (Azure storage account or other Azure resources)
      resource_id = try(
        can(regex("^\\$\\{module\\.storage_accounts\\[\"([^\"]+)\"\\]\\.id\\}$", v.resource_id)) ?
        module.storage_accounts[regex("^\\$\\{module\\.storage_accounts\\[\"([^\"]+)\"\\]\\.id\\}$", v.resource_id)[0]].id :
        v.resource_id,
        v.resource_id
      )
    })
  }
  
  all_ncc_private_endpoints = merge(local.ncc_private_endpoints, var.ncc_private_endpoints)
  enabled_ncc_private_endpoints = {
    for k, v in local.all_ncc_private_endpoints :
    k => v if try(v.enabled, true)
  }

  # Service Principals
  service_principals = {
    for f in try(fileset("${path.module}/resources/databricks/account/service_principals", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/service_principals/${f}"))
  }
  all_service_principals = merge(local.service_principals, var.service_principals)
  enabled_service_principals = {
    for k, v in local.all_service_principals :
    k => v if try(v.enabled, true)
  }

  # =========================================================================
  # Databricks Workspace Resources
  # =========================================================================

  # Storage Credentials
  storage_credentials_raw = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/storage_credentials", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/storage_credentials/${f}"))
  }
  
  # Process storage credentials to resolve dynamic references
  storage_credentials = {
    for k, v in local.storage_credentials_raw : k => merge(v, {
      # Resolve access_connector_id in azure_managed_identity block
      azure_managed_identity = try(v.azure_managed_identity, null) != null ? merge(v.azure_managed_identity, {
        access_connector_id = try(
          can(regex("^\\$\\{module\\.access_connectors\\[\"([^\"]+)\"\\]\\.id\\}$", v.azure_managed_identity.access_connector_id)) ?
          module.access_connectors[regex("^\\$\\{module\\.access_connectors\\[\"([^\"]+)\"\\]\\.id\\}$", v.azure_managed_identity.access_connector_id)[0]].id :
          v.azure_managed_identity.access_connector_id,
          v.azure_managed_identity.access_connector_id
        )
      }) : null
      # Resolve workspace_ids array if it contains template strings
      workspace_ids = try(v.workspace_ids, null) != null ? [
        for ws_ref in v.workspace_ids :
        try(
          can(regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)) ?
          module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)[0]].workspace_id :
          ws_ref,
          ws_ref
        )
      ] : null
    })
  }
  
  all_storage_credentials = merge(local.storage_credentials, var.storage_credentials)
  enabled_storage_credentials = {
    for k, v in local.all_storage_credentials :
    k => v if try(v.enabled, true)
  }

  # External Locations
  external_locations_raw = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/external_locations", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/external_locations/${f}"))
  }
  
  # Process external locations to resolve dynamic workspace_ids references
  external_locations = {
    for k, v in local.external_locations_raw : k => merge(v, {
      # Resolve workspace_ids array if it contains template strings
      workspace_ids = try(v.workspace_ids, null) != null ? [
        for ws_ref in v.workspace_ids :
        try(
          can(regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)) ?
          module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)[0]].workspace_id :
          ws_ref,
          ws_ref
        )
      ] : null
    })
  }
  
  all_external_locations = merge(local.external_locations, var.external_locations)
  enabled_external_locations = {
    for k, v in local.all_external_locations :
    k => v if try(v.enabled, true)
  }

  # Catalogs
  catalogs_raw = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/catalogs", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/catalogs/${f}"))
  }
  
  # Process catalogs to resolve dynamic workspace_ids references
  catalogs = {
    for k, v in local.catalogs_raw : k => merge(v, {
      # Resolve workspace_ids array if it contains template strings
      workspace_ids = try(v.workspace_ids, null) != null ? [
        for ws_ref in v.workspace_ids :
        try(
          can(regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)) ?
          module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", ws_ref)[0]].workspace_id :
          ws_ref,
          ws_ref
        )
      ] : null
    })
  }
  
  all_catalogs = merge(local.catalogs, var.catalogs)
  enabled_catalogs = {
    for k, v in local.all_catalogs :
    k => v if try(v.enabled, true)
  }

  # Schemas
  schemas = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/schemas", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/schemas/${f}"))
  }
  all_schemas = merge(local.schemas, var.schemas)
  enabled_schemas = {
    for k, v in local.all_schemas :
    k => v if try(v.enabled, true)
  }

  # Clusters
  clusters = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/clusters", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/clusters/${f}"))
  }
  all_clusters = merge(local.clusters, var.clusters)
  enabled_clusters = {
    for k, v in local.all_clusters :
    k => v if try(v.enabled, true)
  }

  # Cluster Policies
  cluster_policies = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/cluster_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/cluster_policies/${f}"))
  }
  all_cluster_policies = merge(local.cluster_policies, var.cluster_policies)
  enabled_cluster_policies = {
    for k, v in local.all_cluster_policies :
    k => v if try(v.enabled, true)
  }

  # SQL Warehouses
  sql_warehouses = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/sql_warehouses", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/sql_warehouses/${f}"))
  }
  all_sql_warehouses = merge(local.sql_warehouses, var.sql_warehouses)
  enabled_sql_warehouses = {
    for k, v in local.all_sql_warehouses :
    k => v if try(v.enabled, true)
  }

  # Workspace Folders
  workspace_folders = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/workspace_folders", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/workspace_folders/${f}"))
  }
  all_workspace_folders = merge(local.workspace_folders, var.workspace_folders)
  enabled_workspace_folders = {
    for k, v in local.all_workspace_folders :
    k => v if try(v.enabled, true)
  }

  # Queries
  queries = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/queries", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/queries/${f}"))
  }
  all_queries = merge(local.queries, var.queries)
  enabled_queries = {
    for k, v in local.all_queries :
    k => v if try(v.enabled, true)
  }

  # Alerts
  alerts = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/alerts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/alerts/${f}"))
  }
  all_alerts = merge(local.alerts, var.alerts)
  enabled_alerts = {
    for k, v in local.all_alerts :
    k => v if try(v.enabled, true)
  }

  # Workspace Permissions
  workspace_permissions = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/workspace_permissions", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/workspace_permissions/${f}"))
  }
  all_workspace_permissions = merge(local.workspace_permissions, var.workspace_permissions)
  enabled_workspace_permissions = {
    for k, v in local.all_workspace_permissions :
    k => v if try(v.enabled, true)
  }

  # Workspace Admin Assignments
  workspace_admin_assignments_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/workspace_admin_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/workspace_admin_assignments/${f}"))
  }
  
  # Process workspace admin assignments to resolve dynamic workspace_id references
  workspace_admin_assignments = {
    for k, v in local.workspace_admin_assignments_raw : k => merge(v, {
      # Resolve workspace_id
      workspace_id = try(
        can(regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", v.workspace_id)) ?
        module.workspaces[regex("^\\$\\{module\\.workspaces\\[\"([^\"]+)\"\\]\\.workspace_id\\}$", v.workspace_id)[0]].workspace_id :
        v.workspace_id,
        v.workspace_id
      )
    })
  }
  
  all_workspace_admin_assignments = merge(local.workspace_admin_assignments, var.workspace_admin_assignments)
  enabled_workspace_admin_assignments = {
    for k, v in local.all_workspace_admin_assignments :
    k => v if try(v.enabled, true)
  }
}
