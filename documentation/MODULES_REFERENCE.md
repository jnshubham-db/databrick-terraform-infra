# Modules Reference Guide

## Overview

This document provides a comprehensive reference for all Terraform modules in the mx-ws-solution framework. Each module is documented with its purpose, key components, inputs, outputs, and interdependencies.

---

## Table of Contents

1. [Azure Foundation Modules](#azure-foundation-modules)
   - [Resource Group](#1-resource-group-module)
   - [Access Connector](#2-access-connector-module)
   - [Virtual Network](#3-virtual-network-module)
   - [Workspace VNet Injected](#4-workspace-vnet-injected-module)
   - [Storage Account](#5-storage-account-module)

2. [Databricks Account Modules](#databricks-account-modules)
   - [Metastore](#9-metastore-module)
   - [Metastore Assignment](#10-metastore-assignment-module)
   - [Network Connectivity Config](#11-network-connectivity-config-ncc-module)
   - [NCC Private Endpoint](#12-ncc-private-endpoint-module)
   - [Service Principal](#13-service-principal-module)
   - [Workspace Admin Assignment](#14-workspace-admin-assignment-module)
   - [Budget Policy](#15-budget-policy-module)

3. [Databricks Workspace Modules](#databricks-workspace-modules)
   - [Storage Credential](#16-storage-credential-module)
   - [External Location](#17-external-location-module)
   - [Catalog](#18-catalog-module)
   - [Schema](#19-schema-module)
   - [Cluster Policy](#20-cluster-policy-module)
   - [Cluster](#21-cluster-module)
   - [SQL Warehouse](#22-sql-warehouse-module)
   - [Workspace Folder](#23-workspace-folder-module)
   - [Query](#24-query-module)
   - [Alert](#25-alert-module)
   - [Workspace Permissions](#26-workspace-permissions-module)

---

## Azure Foundation Modules

### Resource Group Module

**Path**: `modules/azure/resource_group/`

#### Purpose
Creates Azure Resource Groups to organize and manage Azure resources.

#### Key Components
- `azurerm_resource_group` - Main resource group resource

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Resource group name |
| `location` | string | Yes | Azure region (e.g., "eastus") |
| `tags` | map | No | Resource tags |
| `enabled` | bool | No | Enable/disable flag (default: true) |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Resource group ID |
| `name` | Resource group name |
| `location` | Resource group location |

#### Dependencies
- **Requires**: None (first resource to be created)
- **Required By**: All other Azure resources

#### Example Usage
See: `resources/azure/resource_groups/*.json`

---

### Access Connector Module

**Path**: `modules/azure/access_connector/`

#### Purpose
Creates Databricks Access Connector with System-Assigned Managed Identity for Unity Catalog storage access.

#### Key Components
- `azurerm_databricks_access_connector` - Access connector with managed identity

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Access connector name |
| `resource_group_name` | string | Yes | Resource group name |
| `location` | string | Yes | Azure region |
| `tags` | map | No | Resource tags |
| `enabled` | bool | No | Enable/disable flag |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Access connector resource ID |
| `principal_id` | Managed identity principal ID (for role assignments) |
| `name` | Access connector name |

#### Dependencies
- **Requires**: Resource Group
- **Required By**: Storage Account, Storage Credentials

#### Critical Notes
- Must be created BEFORE storage account
- Provides managed identity for Unity Catalog
- Principal ID used for storage role assignments

---

### Virtual Network Module

**Path**: `modules/azure/vnet/`

#### Purpose
Creates standalone Virtual Networks with subnets and NSGs (not part of workspace module).

#### Key Components
- `azurerm_virtual_network` - Virtual network
- `azurerm_subnet` - Subnets
- `azurerm_network_security_group` - NSG (optional)

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | VNet name |
| `resource_group_name` | string | Yes | Resource group name |
| `location` | string | Yes | Azure region |
| `address_space` | list(string) | Yes | VNet address space |
| `subnets` | list(object) | Yes | Subnet configurations |
| `tags` | map | No | Resource tags |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | VNet resource ID |
| `name` | VNet name |
| `subnet_ids` | Map of subnet names to IDs |

#### Dependencies
- **Requires**: Resource Group
- **Required By**: VMs, Data Factory, other services

#### Use Cases
- Hub VNet in hub-spoke architecture
- Shared VNet for multiple services
- Separate VNet from Databricks workspace

---

### Workspace VNet Injected Module

**Path**: `modules/azure/workspace_vnet_injected/`

#### Purpose
Creates a complete VNet-injected Databricks workspace including VNet, subnets, NSG, workspace, and private endpoints.

#### Key Components
1. **Virtual Network**
   - `azurerm_virtual_network` - VNet for workspace

2. **Subnets**
   - `azurerm_subnet.public` - Public subnet with Databricks delegation
   - `azurerm_subnet.private` - Private subnet with Databricks delegation
   - `azurerm_subnet.additional` - Additional subnets (for PEs, VMs, etc.)

3. **Network Security**
   - `azurerm_network_security_group` - NSG for Databricks
   - `azurerm_subnet_network_security_group_association` - NSG associations

4. **Workspace**
   - `azurerm_databricks_workspace` - Databricks workspace

5. **Private Endpoints**
   - `azurerm_private_endpoint.browser_auth` - Browser authentication PE
   - `azurerm_private_endpoint.workspace` - Workspace UI/API PE

6. **DNS**
   - `azurerm_private_dns_zone.databricks` - DNS zone (optional)
   - `azurerm_private_dns_zone_virtual_network_link` - VNet links

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `workspace_name` | string | Yes | Workspace name |
| `resource_group_name` | string | Yes | Resource group name |
| `location` | string | Yes | Azure region |
| `sku` | string | No | Workspace SKU (standard/premium/trial) |
| `managed_resource_group_name` | string | No | Managed RG name |
| `vnet_config` | object | Yes | VNet configuration (see below) |
| `private_endpoints` | object | No | Private endpoint configuration |
| `no_public_ip` | bool | No | Disable public IPs (default: true) |
| `public_network_access_enabled` | bool | No | Enable public access (default: false) |
| `tags` | map | No | Resource tags |

#### VNet Configuration Object
```hcl
vnet_config = {
  name                = string  # VNet name
  address_space       = list    # e.g., ["10.0.0.0/16"]
  public_subnet_name  = string  # Public subnet name
  public_subnet_cidr  = string  # e.g., "10.0.1.0/24"
  private_subnet_name = string  # Private subnet name
  private_subnet_cidr = string  # e.g., "10.0.2.0/24"
  nsg_name            = string  # NSG name (optional)
  
  additional_subnets = [        # Optional additional subnets
    {
      name                              = string
      address_prefixes                  = list
      service_endpoints                 = list (optional)
      private_endpoint_network_policies = string (optional)
      delegations                       = list (optional)
    }
  ]
}
```

#### Private Endpoints Configuration
```hcl
private_endpoints = {
  enabled = bool  # Enable private endpoints
  
  # Option 1: Use additional subnets (recommended)
  use_additional_subnets = bool
  workspace_subnet_name  = string  # Name from additional_subnets
  browser_subnet_name    = string  # Name from additional_subnets
  
  # Option 2: Use external subnet IDs (hub-spoke)
  workspace_subnet_id = string  # Full Azure resource ID
  browser_subnet_id   = string  # Full Azure resource ID
  
  # Option 3: Shared subnet
  subnet_id = string  # Single subnet for both PEs
  
  # DNS Configuration
  # Option A: Auto-create DNS zones
  create_dns_zones              = bool
  dns_zone_resource_group_name  = string
  additional_vnet_links         = list  # VNet IDs to link
  
  # Option B: Use existing DNS zone
  private_dns_zone_id = string  # Existing DNS zone ID
}
```

#### Outputs
| Output | Description |
|--------|-------------|
| `workspace_id` | Databricks workspace ID (numeric) |
| `workspace_url` | Workspace URL |
| `workspace_resource_id` | Azure resource ID |
| `vnet_id` | VNet resource ID |
| `subnet_ids` | Map of all subnet IDs (public, private, additional) |
| `nsg_id` | NSG resource ID |
| `private_endpoint_ids` | Map of private endpoint IDs |
| `dns_zone_id` | DNS zone ID (if created) |

#### Dependencies
- **Requires**: Resource Group
- **Required By**: Metastore Assignment, Storage Account (for subnet references)

#### Critical Notes
- Creates 4 types of subnets: public, private, and additional subnets
- Public and private subnets have Databricks delegation
- Both private endpoints use ONE DNS zone: `privatelink.azuredatabricks.net`
- Additional subnets can be used for private endpoints, VMs, Data Factory, etc.

---

### Storage Account Module

**Path**: `modules/azure/storage_account/`

#### Purpose
Creates Azure Storage Accounts with ADLS Gen2 support, network rules, containers, and private endpoints.

#### Key Components
1. **Storage Account**
   - `azurerm_storage_account` - Storage account with HNS

2. **Containers**
   - `azurerm_storage_container` - Storage containers

3. **Role Assignments**
   - `azurerm_role_assignment.blob_data_contributor` - Blob access
   - `azurerm_role_assignment.queue_data_contributor` - Queue access
   - `azurerm_role_assignment.eventgrid_contributor` - EventGrid access

4. **Private Endpoints** (Optional)
   - `azurerm_private_endpoint` - Private endpoints for blob, dfs, etc.
   - `azurerm_private_dns_zone` - DNS zones (if auto-create enabled)

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Storage account name (globally unique) |
| `resource_group_name` | string | Yes | Resource group name |
| `location` | string | Yes | Azure region |
| `account_tier` | string | No | Standard/Premium (default: Standard) |
| `account_replication_type` | string | No | LRS/GRS/RAGRS/ZRS (default: LRS) |
| `is_hns_enabled` | bool | No | Enable ADLS Gen2 (default: false) |
| `public_network_access_enabled` | bool | No | Allow public access (default: false) |
| `access_connector_id` | string | No | Access connector ID for private link |
| `access_connector_principal_id` | string | No | Principal ID for role assignments |
| `network_rules` | object | No | Network rules configuration |
| `containers` | list(object) | No | Containers to create |
| `private_endpoints` | list(object) | No | Private endpoint configurations |
| `tags` | map | No | Resource tags |

#### Network Rules Object
```hcl
network_rules = {
  default_action             = string  # Allow/Deny
  bypass                     = list    # e.g., ["None"]
  ip_rules                   = list    # Allowed IP addresses
  virtual_network_subnet_ids = list    # Allowed subnet IDs
}
```

#### Container Object
```hcl
containers = [
  {
    name                  = string  # Container name
    container_access_type = string  # private/blob/container
  }
]
```

#### Private Endpoint Object
```hcl
private_endpoints = [
  {
    name              = string  # PE name
    subnet_id         = string  # Subnet ID for PE
    subresource_names = list    # ["blob", "dfs", "file", etc.]
    create_dns_zone   = bool    # Auto-create DNS zone
    dns_zone_id       = string  # Existing DNS zone ID
  }
]
```

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Storage account resource ID |
| `name` | Storage account name |
| `primary_blob_endpoint` | Blob endpoint URL |
| `primary_dfs_endpoint` | ADLS Gen2 endpoint URL |
| `container_ids` | Map of container names to IDs |

#### Dependencies
- **Requires**: Resource Group, Access Connector (for Unity Catalog)
- **Required By**: Metastore, External Locations

#### Critical Notes
- For Unity Catalog: Enable HNS, disable public access
- Access Connector ID must be provided for private link access
- Access Connector Principal ID required for role assignments
- Can reference workspace subnets for network rules

---

## Databricks Account Modules

### Metastore Module

**Path**: `modules/databricks/account/metastore/`

#### Purpose
Creates Unity Catalog metastore at the Databricks account level.

#### Key Components
- `databricks_metastore` - Unity Catalog metastore
- `databricks_metastore_data_access` - Storage credential for metastore

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Metastore name |
| `storage_root` | string | Yes | Root storage location (abfss://) |
| `region` | string | Yes | Azure region |
| `owner` | string | No | Metastore owner |
| `force_destroy` | bool | No | Allow destroy with data |
| `delta_sharing_scope` | string | No | INTERNAL/EXTERNAL/INTERNAL_AND_EXTERNAL |

#### Outputs
| Output | Description |
|--------|-------------|
| `metastore_id` | Metastore ID (UUID) |
| `name` | Metastore name |
| `storage_root` | Storage root URL |

#### Dependencies
- **Requires**: Storage Account, Access Connector
- **Required By**: Metastore Assignment, Storage Credentials

#### Critical Notes
- Storage root must be in ADLS Gen2 format: `abfss://container@storage.dfs.core.windows.net/`
- Access Connector must have Storage Blob Data Contributor role on storage
- One metastore can be shared across multiple workspaces in same region

---

### Metastore Assignment Module

**Path**: `modules/databricks/account/metastore_assignment/`

#### Purpose
Assigns a Unity Catalog metastore to a Databricks workspace.

#### Key Components
- `databricks_metastore_assignment` - Assignment resource

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `workspace_id` | string | Yes | Databricks workspace ID (numeric) |
| `metastore_id` | string | Yes | Metastore ID (UUID) |
| `default_catalog_name` | string | No | Default catalog (default: "main") |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Assignment ID |
| `workspace_id` | Workspace ID |
| `metastore_id` | Metastore ID |

#### Dependencies
- **Requires**: Metastore, Workspace
- **Required By**: Storage Credentials, Catalogs

#### Critical Notes
- Must be created before workspace-level Unity Catalog resources
- One workspace can have only one metastore
- Workspace and metastore must be in same region

---

### Network Connectivity Config (NCC) Module

**Path**: `modules/databricks/account/ncc/`

#### Purpose
Creates Network Connectivity Configuration for private connectivity to Azure services.

#### Key Components
- `databricks_mws_network_connectivity_config` - NCC resource

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | NCC name |
| `region` | string | Yes | Azure region |
| `network_connectivity_config_id` | string | No | Existing NCC ID (for updates) |
| `workspace_ids` | list(string) | No | Workspaces to attach NCC to |

#### Outputs
| Output | Description |
|--------|-------------|
| `network_connectivity_config_id` | NCC ID |
| `name` | NCC name |
| `region` | NCC region |

#### Dependencies
- **Requires**: Workspace
- **Required By**: NCC Private Endpoint

#### Critical Notes
- Required for serverless compute private connectivity
- Can be shared across multiple workspaces in same region
- Must be created before NCC Private Endpoints

---

### NCC Private Endpoint Module

**Path**: `modules/databricks/account/ncc_private_endpoint/`

#### Purpose
Creates private endpoint connection from NCC to Azure storage accounts for serverless compute.

#### Key Components
- `databricks_mws_ncc_private_endpoint_rule` - Private endpoint rule

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `network_connectivity_config_id` | string | Yes | NCC ID |
| `resource_id` | string | Yes | Azure resource ID (storage account) |
| `group_id` | string | Yes | Subresource (blob/dfs) |

#### Outputs
| Output | Description |
|--------|-------------|
| `rule_id` | Rule ID |
| `endpoint_name` | Endpoint name |

#### Dependencies
- **Requires**: NCC, Storage Account
- **Required By**: None (enables serverless compute)

#### Critical Notes
- Enables serverless SQL warehouses and notebooks to access storage privately
- One rule per storage account subresource
- Must specify group_id: "blob" or "dfs"

---

### Service Principal Module

**Path**: `modules/databricks/account/service_principal/`

#### Purpose
Manages service principals at Databricks account level.

#### Key Components
- `databricks_service_principal` - Service principal
- `databricks_service_principal_role` - Account roles (optional)

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `application_id` | string | Yes | Azure AD application ID |
| `display_name` | string | Yes | Display name |
| `active` | bool | No | Active status |
| `allow_cluster_create` | bool | No | Allow cluster creation |
| `allow_instance_pool_create` | bool | No | Allow pool creation |
| `workspace_access` | bool | No | Grant workspace access |
| `databricks_sql_access` | bool | No | Grant SQL access |

#### Dependencies
- **Requires**: Workspace (for workspace-level access)
- **Required By**: Workspace Admin Assignment

---

### Workspace Admin Assignment Module

**Path**: `modules/databricks/account/workspace_admin_assignment/`

#### Purpose
Automatically assigns service principals as workspace admins using account-level API.

#### Key Components
- `databricks_mws_permission_assignment` - Permission assignment

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `workspace_id` | string | Yes | Workspace ID (numeric) |
| `principal_id` | string | Yes | Service principal ID |
| `permissions` | list(string) | Yes | Permissions (e.g., ["USER", "ADMIN"]) |

#### Dependencies
- **Requires**: Workspace, Service Principal
- **Required By**: Workspace resources (ensures admin access)

#### Critical Notes
- Uses account-level API (no workspace access needed)
- Runs after workspace creation, before workspace resources
- Eliminates manual admin assignment step

---

### Budget Policy Module

**Path**: `modules/databricks/account/budget_policy/`

#### Purpose
Creates budget policies for cost management at account level.

#### Key Components
- `databricks_budget_configuration` - Budget policy

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `display_name` | string | Yes | Policy name |
| `filter` | object | Yes | Filter configuration |
| `alert_configurations` | list(object) | Yes | Alert configurations |

#### Dependencies
- **Requires**: None (account-level)
- **Required By**: None

---

## Databricks Workspace Modules

### Storage Credential Module

**Path**: `modules/databricks/workspace/storage_credential/`

#### Purpose
Creates Unity Catalog storage credentials for accessing external storage.

#### Key Components
- `databricks_storage_credential` - Storage credential

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Credential name |
| `azure_managed_identity` | object | Yes | Managed identity config |
| `metastore_id` | string | No | Metastore ID |
| `owner` | string | No | Owner |
| `read_only` | bool | No | Read-only access |
| `comment` | string | No | Description |

#### Azure Managed Identity Object
```hcl
azure_managed_identity = {
  access_connector_id = string  # Access Connector resource ID
}
```

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Credential ID |
| `name` | Credential name |

#### Dependencies
- **Requires**: Metastore Assignment, Access Connector
- **Required By**: External Locations

#### Critical Notes
- Must be created after metastore assignment
- Access Connector must have proper role assignments on storage
- One credential can be used for multiple external locations

---

### External Location Module

**Path**: `modules/databricks/workspace/external_location/`

#### Purpose
Creates Unity Catalog external locations pointing to storage paths.

#### Key Components
- `databricks_external_location` - External location

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Location name |
| `url` | string | Yes | Storage URL (abfss://) |
| `credential_name` | string | Yes | Storage credential name |
| `owner` | string | No | Owner |
| `read_only` | bool | No | Read-only access |
| `comment` | string | No | Description |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Location ID |
| `name` | Location name |
| `url` | Storage URL |

#### Dependencies
- **Requires**: Storage Credential
- **Required By**: Catalogs

#### Critical Notes
- URL must be in format: `abfss://container@storage.dfs.core.windows.net/path`
- Storage credential must have access to the storage path
- Used as storage root for catalogs

---

### Catalog Module

**Path**: `modules/databricks/workspace/catalog/`

#### Purpose
Creates Unity Catalog catalogs for data organization.

#### Key Components
- `databricks_catalog` - Catalog

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Catalog name |
| `storage_root` | string | No | Storage location URL |
| `owner` | string | No | Owner |
| `comment` | string | No | Description |
| `properties` | map | No | Custom properties |
| `isolation_mode` | string | No | OPEN/ISOLATED |
| `force_destroy` | bool | No | Allow destroy with data |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Catalog ID |
| `name` | Catalog name |

#### Dependencies
- **Requires**: External Location (if storage_root specified)
- **Required By**: Schemas

#### Critical Notes
- If storage_root specified, external location must exist
- Isolation mode affects data access patterns
- One catalog can contain multiple schemas

---

### Schema Module

**Path**: `modules/databricks/workspace/schema/`

#### Purpose
Creates schemas (databases) within catalogs.

#### Key Components
- `databricks_schema` - Schema

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `catalog_name` | string | Yes | Parent catalog name |
| `name` | string | Yes | Schema name |
| `owner` | string | No | Owner |
| `comment` | string | No | Description |
| `properties` | map | No | Custom properties |
| `force_destroy` | bool | No | Allow destroy with data |

#### Outputs
| Output | Description |
|--------|-------------|
| `id` | Schema ID |
| `name` | Schema name |
| `full_name` | Full name (catalog.schema) |

#### Dependencies
- **Requires**: Catalog
- **Required By**: Tables, Views

---

### Cluster Policy Module

**Path**: `modules/databricks/workspace/cluster_policy/`

#### Purpose
Creates cluster policies for governance and cost control.

#### Key Components
- `databricks_cluster_policy` - Cluster policy

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Policy name |
| `definition` | string | Yes | JSON policy definition |
| `description` | string | No | Description |

#### Dependencies
- **Requires**: Workspace
- **Required By**: Clusters (optional)

---

### Cluster Module

**Path**: `modules/databricks/workspace/cluster/`

#### Purpose
Creates Databricks compute clusters.

#### Key Components
- `databricks_cluster` - Cluster

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `cluster_name` | string | Yes | Cluster name |
| `spark_version` | string | Yes | Spark version |
| `node_type_id` | string | Yes | Node type |
| `autoscale` | object | No | Autoscale config |
| `num_workers` | number | No | Fixed workers |
| `autotermination_minutes` | number | No | Auto-termination |
| `spark_conf` | map | No | Spark configuration |
| `policy_id` | string | No | Cluster policy ID |
| `data_security_mode` | string | No | Security mode |

#### Dependencies
- **Requires**: Workspace
- **Required By**: Jobs, Notebooks

---

### SQL Warehouse Module

**Path**: `modules/databricks/workspace/sql_warehouse/`

#### Purpose
Creates SQL warehouses for SQL analytics.

#### Key Components
- `databricks_sql_endpoint` - SQL warehouse

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Warehouse name |
| `cluster_size` | string | Yes | Size (2X-Small to 4X-Large) |
| `min_num_clusters` | number | No | Min clusters |
| `max_num_clusters` | number | No | Max clusters |
| `auto_stop_mins` | number | No | Auto-stop minutes |
| `enable_photon` | bool | No | Enable Photon |
| `enable_serverless_compute` | bool | No | Enable serverless |
| `warehouse_type` | string | No | CLASSIC/PRO |

#### Dependencies
- **Requires**: Workspace
- **Required By**: Queries, Dashboards

---

### Workspace Folder Module

**Path**: `modules/databricks/workspace/workspace_folder/`

#### Purpose
Creates folders in Databricks workspace for organization.

#### Key Components
- `databricks_directory` - Workspace folder

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | string | Yes | Folder path (e.g., "/Shared/Analytics") |

#### Dependencies
- **Requires**: Workspace
- **Required By**: Notebooks, Files

---

### Query Module

**Path**: `modules/databricks/workspace/query/`

#### Purpose
Creates SQL queries in Databricks SQL.

#### Key Components
- `databricks_sql_query` - SQL query

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Query name |
| `query` | string | Yes | SQL query text |
| `data_source_id` | string | Yes | SQL warehouse ID |
| `parent` | string | No | Parent folder |
| `description` | string | No | Description |

#### Dependencies
- **Requires**: SQL Warehouse
- **Required By**: Alerts, Dashboards

---

### Alert Module

**Path**: `modules/databricks/workspace/alert/`

#### Purpose
Creates alerts based on query results.

#### Key Components
- `databricks_sql_alert` - SQL alert

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Alert name |
| `query_id` | string | Yes | Query ID |
| `condition` | object | Yes | Alert condition |
| `custom_body` | string | No | Email body |
| `custom_subject` | string | No | Email subject |

#### Dependencies
- **Requires**: Query
- **Required By**: None

---

### Workspace Permissions Module

**Path**: `modules/databricks/workspace/workspace_permissions/`

#### Purpose
Manages workspace-level permissions and access control.

#### Key Components
- `databricks_permissions` - Permission assignments

#### Key Inputs
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `workspace_id` | string | Yes | Workspace ID |
| `service_principal_application_ids` | list | No | SP app IDs |
| `groups` | list | No | Groups to create |
| `group_members` | map | No | Group memberships |

#### Dependencies
- **Requires**: Workspace, Service Principals
- **Required By**: None

---

## Module Dependency Graph

```
Resource Group
    ├─→ Access Connector
    │       ├─→ Storage Account
    │       │       ├─→ Metastore
    │       │       └─→ NCC Private Endpoint
    │       └─→ Storage Credential
    │
    └─→ Workspace (VNet Injected)
            ├─→ Metastore Assignment
            │       └─→ Storage Credential
            │               └─→ External Location
            │                       └─→ Catalog
            │                               └─→ Schema
            │
            ├─→ Service Principal
            │       └─→ Workspace Admin Assignment
            │               └─→ [All Workspace Resources]
            │
            ├─→ NCC
            │       └─→ NCC Private Endpoint
            │
            ├─→ Cluster Policy
            │       └─→ Cluster
            │
            ├─→ SQL Warehouse
            │       └─→ Query
            │               └─→ Alert
            │
            └─→ Workspace Folder
```

---

## Provider Requirements

### Azure Provider
- Used by: All Azure modules
- Authentication: Service Principal or Azure CLI
- Required permissions: Contributor + User Access Administrator

### Databricks Account Provider
- Used by: Account-level modules
- Authentication: Service Principal with Account Admin role
- Alias: `databricks.account`

### Databricks Workspace Provider
- Used by: Workspace-level modules
- Authentication: Azure OAuth M2M or Service Principal
- Alias: `databricks.workspace`
- Requires: Workspace must exist and SP must have admin access

---

## Common Patterns

### Dynamic References
Many modules support dynamic references to other module outputs:

```json
{
  "access_connector_id": "${module.access_connectors[\"my-connector\"].id}",
  "workspace_id": "${module.workspaces[\"my-workspace\"].workspace_id}",
  "subnet_id": "${module.workspaces[\"my-workspace\"].subnet_ids[\"snet-pe\"]}"
}
```

### Enable/Disable Pattern
All modules support the `enabled` flag:

```json
{
  "enabled": true,
  "name": "my-resource"
}
```

### Workspace Binding
Unity Catalog resources can be bound to specific workspaces:

```json
{
  "name": "my-catalog",
  "workspace_ids": [
    "${module.workspaces[\"workspace1\"].workspace_id}",
    "${module.workspaces[\"workspace2\"].workspace_id}"
  ]
}
```

