# Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing infrastructure using the mx-ws-solution Terraform framework. It covers how to create JSON configuration files for each resource type with detailed explanations and examples.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Prerequisites](#prerequisites)
3. [Authentication Setup](#authentication-setup)
4. [Resource Implementation Guide](#resource-implementation-guide)
   - [Phase 1: Azure Foundation](#phase-1-azure-foundation)
   - [Phase 2: Storage Resources](#phase-2-storage-resources)
   - [Phase 3: Databricks Account](#phase-3-databricks-account)
   - [Phase 4: Workspace Admin](#phase-4-workspace-admin)
   - [Phase 5: Workspace Objects](#phase-5-workspace-objects)
5. [Common Patterns](#common-patterns)
6. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Framework Structure

```
mx-ws-solution/
├── resources/                    # Your JSON configuration files go here
│   ├── azure/                   # Azure resources
│   │   ├── resource_groups/     # *.json files
│   │   ├── access_connectors/   # *.json files
│   │   ├── workspaces/          # *.json files
│   │   ├── storage_accounts/    # *.json files
│   │   └── ...
│   └── databricks/              # Databricks resources
│       ├── account/             # Account-level resources
│       │   ├── metastores/
│       │   ├── ncc/
│       │   └── ...
│       └── workspace/           # Workspace-level resources
│           ├── storage_credentials/
│           ├── catalogs/
│           └── ...
├── modules/                     # Terraform modules (don't modify)
└── main.tf                      # Main orchestration (don't modify)
```

### How It Works

1. **Create JSON files** in the appropriate `resources/` subdirectory
2. **Name your files** descriptively (e.g., `prod-workspace.json`, `dev-cluster.json`)
3. **Run Terraform** - files are automatically loaded and processed
4. **No need to edit** `main.tf` or module files

---

## Prerequisites

### Required Tools
- Terraform >= 1.5.0
- Azure CLI (for development approach)
- Access to Azure subscription
- Access to Databricks account

### Required Permissions

**Azure**:
- Contributor role (for resource creation)
- User Access Administrator (for role assignments)

**Databricks**:
- Account Admin (for account-level resources)
- Workspace Admin (for workspace-level resources)

---

## Authentication Setup

### Option 1: Development Approach (Azure CLI + Service Principal)

```bash
# 1. Login to Azure
az login

# 2. Set subscription
az account set --subscription "your-subscription-id"

# 3. Create Service Principal (for Databricks only)
APP_ID=$(az ad app create --display-name "Databricks-Dev-SP" --query appId -o tsv)
az ad sp create --id "$APP_ID"
CLIENT_SECRET=$(az ad app credential reset --id "$APP_ID" --query password -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# 4. Configure terraform.tfvars
cat > terraform.tfvars <<EOF
# Azure authentication (uses az login)
azure_subscription_id = "your-subscription-id"

# Databricks workspace authentication
databricks_workspace_host = "https://adb-xxxxx.azuredatabricks.net"
databricks_workspace_resource_id = "/subscriptions/.../workspaces/..."
databricks_client_id = "$APP_ID"
databricks_client_secret = "$CLIENT_SECRET"
azure_tenant_id = "$TENANT_ID"

# Databricks account authentication (optional)
databricks_account_host = "https://accounts.azuredatabricks.net"
databricks_account_id = "your-account-id"
databricks_account_client_id = "$APP_ID"
databricks_account_client_secret = "$CLIENT_SECRET"
EOF
```

### Option 2: Production Approach (Service Principal for Everything)

See `docs/AUTHENTICATION_GUIDE.md` for complete setup.

---

## Resource Implementation Guide

### Phase 1: Azure Foundation

#### 1.1 Resource Group

**File**: `resources/azure/resource_groups/my-rg.json`

```json
{
  "enabled": true,
  "name": "rg-databricks-prod",
  "location": "eastus",
  "tags": {
    "environment": "prod",
    "project": "analytics",
    "managed_by": "terraform"
  }
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `enabled` | No | Enable/disable this resource | `true` (default) |
| `name` | Yes | Resource group name | `"rg-databricks-prod"` |
| `location` | Yes | Azure region | `"eastus"`, `"westus2"` |
| `tags` | No | Resource tags for organization | `{"environment": "prod"}` |

**Best Practices**:
- Use consistent naming: `rg-{service}-{environment}`
- Always include environment and project tags
- Create separate RGs for different environments

---

#### 1.2 Access Connector

**File**: `resources/azure/access_connectors/my-connector.json`

```json
{
  "enabled": true,
  "name": "ac-databricks-prod",
  "resource_group_name": "rg-databricks-prod",
  "location": "eastus",
  "tags": {
    "environment": "prod",
    "purpose": "unity-catalog"
  }
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `enabled` | No | Enable/disable this resource | `true` |
| `name` | Yes | Access connector name (globally unique) | `"ac-databricks-prod"` |
| `resource_group_name` | Yes | Resource group name | `"rg-databricks-prod"` |
| `location` | Yes | Azure region (must match RG) | `"eastus"` |
| `tags` | No | Resource tags | `{"purpose": "unity-catalog"}` |

**Best Practices**:
- Create one access connector per environment
- Name it clearly: `ac-databricks-{environment}`
- Tag with purpose: "unity-catalog"

**What It Does**:
- Creates a managed identity
- Used by Unity Catalog to access storage
- Gets role assignments on storage accounts

---

#### 1.3 Databricks Workspace (VNet Injected)

**File**: `resources/azure/workspaces/my-workspace.json`

**Example 1: Complete Workspace with Auto DNS**

```json
{
  "enabled": true,
  "workspace_name": "dbx-ws-prod",
  "resource_group_name": "rg-databricks-prod",
  "location": "eastus",
  "sku": "premium",
  "managed_resource_group_name": "dbx-ws-prod-managed-rg",
  
  "vnet_config": {
    "name": "vnet-databricks-prod",
    "address_space": ["10.100.0.0/16"],
    "public_subnet_name": "snet-databricks-public",
    "public_subnet_cidr": "10.100.0.0/18",
    "private_subnet_name": "snet-databricks-private",
    "private_subnet_cidr": "10.100.64.0/18",
    "nsg_name": "nsg-databricks-prod",
    
    "additional_subnets": [
      {
        "name": "snet-workspace-pe",
        "address_prefixes": ["10.100.128.0/22"],
        "private_endpoint_network_policies": "Disabled",
        "service_endpoints": ["Microsoft.Storage"]
      },
      {
        "name": "snet-browser-pe",
        "address_prefixes": ["10.100.132.0/22"],
        "private_endpoint_network_policies": "Disabled"
      }
    ]
  },
  
  "private_endpoints": {
    "enabled": true,
    "create_dns_zones": true,
    "dns_zone_resource_group_name": "rg-databricks-prod",
    "use_additional_subnets": true,
    "workspace_subnet_name": "snet-workspace-pe",
    "browser_subnet_name": "snet-browser-pe",
    "additional_vnet_links": []
  },
  
  "no_public_ip": true,
  "public_network_access_enabled": false,
  "network_security_group_rules_required": "NoAzureDatabricksRules",
  
  "tags": {
    "environment": "prod",
    "project": "analytics"
  }
}
```

**Field Explanations**:

**Workspace Configuration**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `workspace_name` | Yes | Workspace name | `"dbx-ws-prod"` |
| `resource_group_name` | Yes | Resource group name | `"rg-databricks-prod"` |
| `location` | Yes | Azure region | `"eastus"` |
| `sku` | No | Workspace tier | `"premium"` (recommended), `"standard"`, `"trial"` |
| `managed_resource_group_name` | No | Managed RG name | `"dbx-ws-prod-managed-rg"` |
| `no_public_ip` | No | Disable public IPs | `true` (recommended for security) |
| `public_network_access_enabled` | No | Allow public access | `false` (recommended for security) |
| `network_security_group_rules_required` | No | NSG rules mode | `"NoAzureDatabricksRules"` (for private endpoints) |

**VNet Configuration**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | VNet name | `"vnet-databricks-prod"` |
| `address_space` | Yes | VNet CIDR | `["10.100.0.0/16"]` |
| `public_subnet_name` | Yes | Public subnet name | `"snet-databricks-public"` |
| `public_subnet_cidr` | Yes | Public subnet CIDR | `"10.100.0.0/18"` (16,384 IPs) |
| `private_subnet_name` | Yes | Private subnet name | `"snet-databricks-private"` |
| `private_subnet_cidr` | Yes | Private subnet CIDR | `"10.100.64.0/18"` (16,384 IPs) |
| `nsg_name` | No | NSG name | `"nsg-databricks-prod"` |
| `additional_subnets` | No | Additional subnets | See below |

**Additional Subnets** (for private endpoints, VMs, etc.):

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Subnet name | `"snet-workspace-pe"` |
| `address_prefixes` | Yes | Subnet CIDR | `["10.100.128.0/22"]` (1,024 IPs) |
| `private_endpoint_network_policies` | No | PE policies | `"Disabled"` (required for PEs) |
| `service_endpoints` | No | Service endpoints | `["Microsoft.Storage"]` |

**Private Endpoints Configuration**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `enabled` | Yes | Enable private endpoints | `true` |
| `use_additional_subnets` | No | Use subnets from additional_subnets | `true` |
| `workspace_subnet_name` | Conditional | Subnet name for workspace PE | `"snet-workspace-pe"` |
| `browser_subnet_name` | Conditional | Subnet name for browser PE | `"snet-browser-pe"` |
| `workspace_subnet_id` | Conditional | External subnet ID for workspace PE | Full Azure resource ID |
| `browser_subnet_id` | Conditional | External subnet ID for browser PE | Full Azure resource ID |
| `subnet_id` | Conditional | Shared subnet for both PEs | Full Azure resource ID |
| `create_dns_zones` | No | Auto-create DNS zones | `true` |
| `dns_zone_resource_group_name` | Conditional | RG for DNS zones | `"rg-databricks-prod"` |
| `private_dns_zone_id` | Conditional | Existing DNS zone ID | Full Azure resource ID |
| `additional_vnet_links` | No | Additional VNets to link | `[]` |

**Subnet Configuration Options**:

Choose ONE of these options:

1. **Use Additional Subnets** (Recommended for new deployments):
```json
{
  "use_additional_subnets": true,
  "workspace_subnet_name": "snet-workspace-pe",
  "browser_subnet_name": "snet-browser-pe"
}
```

2. **Use External Subnets** (Hub-spoke architecture):
```json
{
  "workspace_subnet_id": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}",
  "browser_subnet_id": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
}
```

3. **Use Shared Subnet** (Simple deployments):
```json
{
  "subnet_id": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
}
```

**DNS Configuration Options**:

Choose ONE of these options:

1. **Auto-create DNS Zones** (Recommended for new deployments):
```json
{
  "create_dns_zones": true,
  "dns_zone_resource_group_name": "rg-databricks-prod",
  "additional_vnet_links": []
}
```

2. **Use Existing DNS Zone** (Hub-spoke architecture):
```json
{
  "private_dns_zone_id": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/privateDnsZones/privatelink.azuredatabricks.net"
}
```

**CIDR Planning Guide**:

For a `/16` VNet (10.100.0.0/16 = 65,536 IPs):
- Public Subnet: `/18` = 16,384 IPs (25% of VNet)
- Private Subnet: `/18` = 16,384 IPs (25% of VNet)
- Workspace PE Subnet: `/22` = 1,024 IPs
- Browser PE Subnet: `/22` = 1,024 IPs
- Reserved for future: Remaining ~30,000 IPs

**Best Practices**:
- Use `/16` for VNet to allow growth
- Use `/18` for Databricks subnets (public/private)
- Use `/22` for PE subnets (1,024 IPs each)
- Always set `no_public_ip: true` for security
- Always set `public_network_access_enabled: false` for security
- Use `premium` SKU for production (required for some features)

**What It Creates**:
1. Virtual Network with 4 subnets
2. Network Security Group
3. Databricks Workspace
4. 2 Private Endpoints (browser + workspace)
5. Private DNS Zone (if auto-create enabled)
6. VNet links for DNS resolution

---

### Phase 2: Storage Resources

#### 2.1 Storage Account

**File**: `resources/azure/storage_accounts/my-storage.json`

**Example 1: Unity Catalog Storage (Basic)**

```json
{
  "enabled": true,
  "name": "stdatabricksprod001",
  "resource_group_name": "rg-databricks-prod",
  "location": "eastus",
  "account_tier": "Standard",
  "account_replication_type": "LRS",
  "is_hns_enabled": true,
  "public_network_access_enabled": false,
  
  "network_rules": {
    "default_action": "Deny",
    "bypass": ["None"]
  },
  
  "containers": [
    {
      "name": "metastore",
      "container_access_type": "private"
    },
    {
      "name": "data",
      "container_access_type": "private"
    }
  ],
  
  "access_connector_id": "${module.access_connectors[\"ac-databricks-prod\"].id}",
  "access_connector_principal_id": "${module.access_connectors[\"ac-databricks-prod\"].principal_id}",
  
  "tags": {
    "environment": "prod",
    "purpose": "unity-catalog"
  }
}
```

**Example 2: With Private Endpoints and Dynamic Subnet References**

```json
{
  "enabled": true,
  "name": "stdatabricksprod001",
  "resource_group_name": "rg-databricks-prod",
  "location": "eastus",
  "account_tier": "Standard",
  "account_replication_type": "LRS",
  "is_hns_enabled": true,
  "public_network_access_enabled": false,
  
  "network_rules": {
    "default_action": "Deny",
    "bypass": ["None"],
    "virtual_network_subnet_ids": [
      "${module.workspaces[\"dbx-ws-prod\"].subnet_ids[\"snet-databricks-public\"]}",
      "${module.workspaces[\"dbx-ws-prod\"].subnet_ids[\"snet-databricks-private\"]}"
    ]
  },
  
  "containers": [
    {
      "name": "metastore",
      "container_access_type": "private"
    }
  ],
  
  "access_connector_id": "${module.access_connectors[\"ac-databricks-prod\"].id}",
  "access_connector_principal_id": "${module.access_connectors[\"ac-databricks-prod\"].principal_id}",
  
  "private_endpoints": [
    {
      "name": "pe-storage-blob",
      "subnet_id": "${module.workspaces[\"dbx-ws-prod\"].subnet_ids[\"snet-workspace-pe\"]}",
      "subresource_names": ["blob"],
      "create_dns_zone": true
    },
    {
      "name": "pe-storage-dfs",
      "subnet_id": "${module.workspaces[\"dbx-ws-prod\"].subnet_ids[\"snet-workspace-pe\"]}",
      "subresource_names": ["dfs"],
      "create_dns_zone": true
    }
  ],
  
  "create_dns_zones": true,
  "dns_zone_resource_group_name": "rg-databricks-prod",
  
  "tags": {
    "environment": "prod",
    "purpose": "unity-catalog"
  }
}
```

**Field Explanations**:

**Storage Account Configuration**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Storage account name (globally unique, 3-24 chars, lowercase, no hyphens) | `"stdatabricksprod001"` |
| `resource_group_name` | Yes | Resource group name | `"rg-databricks-prod"` |
| `location` | Yes | Azure region | `"eastus"` |
| `account_tier` | No | Performance tier | `"Standard"` (default), `"Premium"` |
| `account_replication_type` | No | Replication type | `"LRS"` (default), `"GRS"`, `"RAGRS"`, `"ZRS"` |
| `is_hns_enabled` | No | Enable ADLS Gen2 | `true` (required for Unity Catalog) |
| `public_network_access_enabled` | No | Allow public access | `false` (recommended) |
| `access_connector_id` | No | Access connector resource ID | Dynamic reference |
| `access_connector_principal_id` | No | Access connector principal ID | Dynamic reference |

**Network Rules**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `default_action` | Yes | Default network action | `"Deny"` (recommended), `"Allow"` |
| `bypass` | No | Services to bypass | `["None"]`, `["AzureServices"]` |
| `ip_rules` | No | Allowed IP addresses | `["1.2.3.4", "5.6.7.8"]` |
| `virtual_network_subnet_ids` | No | Allowed subnet IDs | Dynamic references to workspace subnets |

**Containers**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Container name | `"metastore"`, `"data"` |
| `container_access_type` | No | Access level | `"private"` (default), `"blob"`, `"container"` |

**Private Endpoints**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Private endpoint name | `"pe-storage-blob"` |
| `subnet_id` | Yes | Subnet ID for PE | Dynamic reference |
| `subresource_names` | Yes | Storage subresource | `["blob"]`, `["dfs"]`, `["file"]` |
| `create_dns_zone` | No | Auto-create DNS zone | `true` |
| `dns_zone_id` | No | Existing DNS zone ID | Full Azure resource ID |

**Dynamic References**:

Access Connector:
```json
"access_connector_id": "${module.access_connectors[\"ac-name\"].id}"
"access_connector_principal_id": "${module.access_connectors[\"ac-name\"].principal_id}"
```

Workspace Subnets:
```json
"subnet_id": "${module.workspaces[\"workspace-name\"].subnet_ids[\"subnet-name\"]}"
```

**Best Practices**:
- Name: `st{service}{environment}{number}` (e.g., `stdatabricksprod001`)
- Always enable HNS for Unity Catalog (`is_hns_enabled: true`)
- Disable public access (`public_network_access_enabled: false`)
- Use `Deny` for default network action
- Create separate containers for metastore and data
- Use dynamic references for access connector and subnets
- Create private endpoints for `blob` and `dfs` subresources

**What It Creates**:
1. Storage account with ADLS Gen2
2. Containers for data storage
3. Role assignments for access connector:
   - Storage Blob Data Contributor
   - Storage Queue Data Contributor
   - EventGrid EventSubscription Contributor
4. Private endpoints (optional)
5. DNS zones for private endpoints (optional)

---

### Phase 3: Databricks Account

#### 3.1 Metastore

**File**: `resources/databricks/account/metastores/my-metastore.json`

```json
{
  "enabled": true,
  "name": "metastore-prod-eastus",
  "storage_root": "abfss://metastore@stdatabricksprod001.dfs.core.windows.net/",
  "region": "eastus",
  "owner": "account users",
  "force_destroy": false,
  "delta_sharing_scope": "INTERNAL_AND_EXTERNAL",
  "delta_sharing_recipient_token_lifetime_in_seconds": 0,
  "delta_sharing_organization_name": "MyOrg"
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Metastore name | `"metastore-prod-eastus"` |
| `storage_root` | Yes | Root storage location (abfss format) | `"abfss://metastore@storage.dfs.core.windows.net/"` |
| `region` | Yes | Azure region (must match workspace) | `"eastus"` |
| `owner` | No | Metastore owner | `"account users"`, `"user@example.com"` |
| `force_destroy` | No | Allow destroy with data | `false` (recommended) |
| `delta_sharing_scope` | No | Delta sharing scope | `"INTERNAL"`, `"EXTERNAL"`, `"INTERNAL_AND_EXTERNAL"` |
| `delta_sharing_recipient_token_lifetime_in_seconds` | No | Token lifetime | `0` (no expiration) |
| `delta_sharing_organization_name` | No | Organization name | `"MyOrg"` |

**Storage Root Format**:
```
abfss://{container-name}@{storage-account-name}.dfs.core.windows.net/
```

**Best Practices**:
- Name: `metastore-{environment}-{region}`
- One metastore per region
- Use `force_destroy: false` for production
- Set owner to `"account users"` for shared access
- Ensure storage account has HNS enabled
- Ensure access connector has proper role assignments

**Prerequisites**:
1. Storage account with HNS enabled
2. Container created (e.g., "metastore")
3. Access connector with role assignments on storage

---

#### 3.2 Metastore Assignment

**File**: `resources/databricks/account/metastore_assignments/my-assignment.json`

```json
{
  "enabled": true,
  "workspace_id": "${module.workspaces[\"dbx-ws-prod\"].workspace_id}",
  "metastore_id": "${module.metastores[\"metastore-prod-eastus\"].metastore_id}",
  "default_catalog_name": "main"
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `workspace_id` | Yes | Databricks workspace ID (numeric) | Dynamic reference |
| `metastore_id` | Yes | Metastore ID (UUID) | Dynamic reference |
| `default_catalog_name` | No | Default catalog | `"main"` (default) |

**Dynamic References**:
```json
"workspace_id": "${module.workspaces[\"workspace-name\"].workspace_id}"
"metastore_id": "${module.metastores[\"metastore-name\"].metastore_id}"
```

**Best Practices**:
- One assignment per workspace
- Use dynamic references for IDs
- Keep default catalog as "main"

**What It Does**:
- Links metastore to workspace
- Enables Unity Catalog in workspace
- Sets default catalog

---

#### 3.3 Network Connectivity Config (NCC)

**File**: `resources/databricks/account/ncc/my-ncc.json`

```json
{
  "enabled": true,
  "name": "ncc-prod-eastus",
  "region": "eastus",
  "workspace_ids": [
    "${module.workspaces[\"dbx-ws-prod\"].workspace_id}"
  ]
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | NCC name | `"ncc-prod-eastus"` |
| `region` | Yes | Azure region | `"eastus"` |
| `workspace_ids` | No | Workspaces to attach | Array of workspace IDs |

**Best Practices**:
- Name: `ncc-{environment}-{region}`
- One NCC per region
- Can be shared across workspaces

**What It Does**:
- Creates network connectivity configuration
- Enables private connectivity to Azure services
- Required for serverless compute

---

#### 3.4 NCC Private Endpoint

**File**: `resources/databricks/account/ncc_private_endpoints/my-ncc-pe.json`

```json
{
  "enabled": true,
  "network_connectivity_config_id": "${module.ncc_configs[\"ncc-prod-eastus\"].network_connectivity_config_id}",
  "resource_id": "${module.storage_accounts[\"stdatabricksprod001\"].id}",
  "group_id": "dfs"
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `network_connectivity_config_id` | Yes | NCC ID | Dynamic reference |
| `resource_id` | Yes | Azure resource ID (storage account) | Dynamic reference |
| `group_id` | Yes | Subresource type | `"blob"`, `"dfs"`, `"file"` |

**Best Practices**:
- Create one rule per storage account subresource
- Use `"dfs"` for ADLS Gen2
- Use `"blob"` for blob storage

**What It Does**:
- Creates private endpoint from NCC to storage
- Enables serverless compute to access storage privately
- Required for serverless SQL warehouses and notebooks

---

### Phase 4: Workspace Admin

#### 4.1 Service Principal

**File**: `resources/databricks/account/service_principals/my-sp.json`

```json
{
  "enabled": true,
  "application_id": "00000000-0000-0000-0000-000000000000",
  "display_name": "Terraform Deployer",
  "active": true,
  "allow_cluster_create": true,
  "allow_instance_pool_create": true,
  "workspace_access": true,
  "databricks_sql_access": true
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `application_id` | Yes | Azure AD application ID | UUID |
| `display_name` | Yes | Display name | `"Terraform Deployer"` |
| `active` | No | Active status | `true` |
| `allow_cluster_create` | No | Allow cluster creation | `true` |
| `allow_instance_pool_create` | No | Allow pool creation | `true` |
| `workspace_access` | No | Grant workspace access | `true` |
| `databricks_sql_access` | No | Grant SQL access | `true` |

**Best Practices**:
- Use descriptive display names
- Grant only necessary permissions
- Keep service principals active

---

#### 4.2 Workspace Admin Assignment

**File**: `resources/databricks/account/workspace_admin_assignments/my-assignment.json`

```json
{
  "enabled": true,
  "workspace_id": "${module.workspaces[\"dbx-ws-prod\"].workspace_id}",
  "principal_id": "00000000-0000-0000-0000-000000000000",
  "permissions": ["USER", "ADMIN"]
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `workspace_id` | Yes | Workspace ID (numeric) | Dynamic reference |
| `principal_id` | Yes | Service principal ID | UUID |
| `permissions` | Yes | Permission levels | `["USER"]`, `["ADMIN"]`, `["USER", "ADMIN"]` |

**Best Practices**:
- Use `["USER", "ADMIN"]` for full admin access
- Use dynamic workspace ID references
- Run before creating workspace resources

**What It Does**:
- Adds service principal as workspace admin
- Uses account-level API (no workspace access needed)
- Eliminates manual admin assignment

---

### Phase 5: Workspace Objects

#### 5.1 Storage Credential

**File**: `resources/databricks/workspace/storage_credentials/my-credential.json`

```json
{
  "enabled": true,
  "name": "storage_credential_prod",
  "azure_managed_identity": {
    "access_connector_id": "${module.access_connectors[\"ac-databricks-prod\"].id}"
  },
  "owner": "account users",
  "read_only": false,
  "force_destroy": false,
  "skip_validation": false,
  "comment": "Storage credential for Unity Catalog"
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Credential name | `"storage_credential_prod"` |
| `azure_managed_identity` | Yes | Managed identity config | See below |
| `owner` | No | Owner | `"account users"` |
| `read_only` | No | Read-only access | `false` |
| `force_destroy` | No | Allow destroy | `false` |
| `skip_validation` | No | Skip validation | `false` |
| `comment` | No | Description | `"Storage credential for Unity Catalog"` |

**Azure Managed Identity**:
```json
"azure_managed_identity": {
  "access_connector_id": "${module.access_connectors[\"ac-name\"].id}"
}
```

**Best Practices**:
- Name: `storage_credential_{environment}`
- Use dynamic access connector reference
- Set owner to `"account users"` for shared access
- Use `read_only: false` for write access

**Prerequisites**:
- Metastore assignment completed
- Access connector with role assignments on storage

---

#### 5.2 External Location

**File**: `resources/databricks/workspace/external_locations/my-location.json`

```json
{
  "enabled": true,
  "name": "external_location_prod",
  "url": "abfss://data@stdatabricksprod001.dfs.core.windows.net/",
  "credential_name": "storage_credential_prod",
  "owner": "account users",
  "read_only": false,
  "force_destroy": false,
  "skip_validation": false,
  "comment": "External location for production data"
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Location name | `"external_location_prod"` |
| `url` | Yes | Storage URL (abfss format) | `"abfss://container@storage.dfs.core.windows.net/"` |
| `credential_name` | Yes | Storage credential name | `"storage_credential_prod"` |
| `owner` | No | Owner | `"account users"` |
| `read_only` | No | Read-only access | `false` |
| `force_destroy` | No | Allow destroy | `false` |
| `skip_validation` | No | Skip validation | `false` |
| `comment` | No | Description | `"External location for production data"` |

**URL Format**:
```
abfss://{container-name}@{storage-account-name}.dfs.core.windows.net/{path}
```

**Best Practices**:
- Name: `external_location_{purpose}`
- Use specific paths for different purposes
- Ensure credential has access to the path

---

#### 5.3 Catalog

**File**: `resources/databricks/workspace/catalogs/my-catalog.json`

```json
{
  "enabled": true,
  "name": "prod_catalog",
  "storage_root": "abfss://data@stdatabricksprod001.dfs.core.windows.net/catalog/",
  "owner": "account users",
  "comment": "Production data catalog",
  "properties": {
    "purpose": "production"
  },
  "isolation_mode": "OPEN",
  "force_destroy": false
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Catalog name | `"prod_catalog"` |
| `storage_root` | No | Storage location | `"abfss://..."` |
| `owner` | No | Owner | `"account users"` |
| `comment` | No | Description | `"Production data catalog"` |
| `properties` | No | Custom properties | `{"purpose": "production"}` |
| `isolation_mode` | No | Isolation mode | `"OPEN"`, `"ISOLATED"` |
| `force_destroy` | No | Allow destroy with data | `false` |

**Best Practices**:
- Name: `{environment}_catalog`
- Use storage_root for managed catalogs
- Set owner to `"account users"` for shared access
- Use `isolation_mode: "OPEN"` for most cases

---

#### 5.4 Schema

**File**: `resources/databricks/workspace/schemas/my-schema.json`

```json
{
  "enabled": true,
  "catalog_name": "prod_catalog",
  "name": "analytics",
  "owner": "account users",
  "comment": "Analytics schema",
  "properties": {
    "team": "analytics"
  },
  "force_destroy": false
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `catalog_name` | Yes | Parent catalog name | `"prod_catalog"` |
| `name` | Yes | Schema name | `"analytics"` |
| `owner` | No | Owner | `"account users"` |
| `comment` | No | Description | `"Analytics schema"` |
| `properties` | No | Custom properties | `{"team": "analytics"}` |
| `force_destroy` | No | Allow destroy with data | `false` |

**Best Practices**:
- Name schemas by team or purpose
- Use properties to tag ownership
- Set owner to team or group

---

#### 5.5 Cluster

**File**: `resources/databricks/workspace/clusters/my-cluster.json`

```json
{
  "enabled": true,
  "cluster_name": "Analytics Cluster",
  "spark_version": "13.3.x-scala2.12",
  "node_type_id": "Standard_DS3_v2",
  "autotermination_minutes": 30,
  "data_security_mode": "SINGLE_USER",
  
  "autoscale": {
    "min_workers": 1,
    "max_workers": 5
  },
  
  "spark_conf": {
    "spark.databricks.delta.preview.enabled": "true",
    "spark.sql.adaptive.enabled": "true"
  },
  
  "spark_env_vars": {
    "ENV": "prod"
  },
  
  "custom_tags": {
    "team": "analytics",
    "cost_center": "engineering"
  }
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `cluster_name` | Yes | Cluster name | `"Analytics Cluster"` |
| `spark_version` | Yes | Spark version | `"13.3.x-scala2.12"` |
| `node_type_id` | Yes | Node type | `"Standard_DS3_v2"` |
| `autotermination_minutes` | No | Auto-termination | `30` (minutes) |
| `data_security_mode` | No | Security mode | `"SINGLE_USER"`, `"USER_ISOLATION"`, `"NONE"` |
| `autoscale` | No | Autoscale config | See below |
| `num_workers` | No | Fixed workers | `2` (use instead of autoscale) |
| `spark_conf` | No | Spark configuration | Map of settings |
| `spark_env_vars` | No | Environment variables | Map of variables |
| `custom_tags` | No | Custom tags | Map of tags |
| `policy_id` | No | Cluster policy ID | Policy ID |

**Autoscale Configuration**:
```json
"autoscale": {
  "min_workers": 1,
  "max_workers": 5
}
```

**Best Practices**:
- Use autoscale for variable workloads
- Set autotermination to save costs
- Use `SINGLE_USER` mode for Unity Catalog
- Tag clusters with team and cost center
- Choose appropriate node types for workload

**Common Node Types**:
- `Standard_DS3_v2` - General purpose (4 cores, 14 GB RAM)
- `Standard_DS4_v2` - Larger (8 cores, 28 GB RAM)
- `Standard_E4s_v3` - Memory optimized (4 cores, 32 GB RAM)

---

#### 5.6 SQL Warehouse

**File**: `resources/databricks/workspace/sql_warehouses/my-warehouse.json`

```json
{
  "enabled": true,
  "name": "Production SQL Warehouse",
  "cluster_size": "Medium",
  "min_num_clusters": 1,
  "max_num_clusters": 3,
  "auto_stop_mins": 20,
  "spot_instance_policy": "COST_OPTIMIZED",
  "warehouse_type": "PRO",
  "enable_photon": true,
  "enable_serverless_compute": true,
  "channel": {
    "name": "CHANNEL_NAME_CURRENT"
  },
  "tags": {
    "custom_tags": [
      {
        "key": "team",
        "value": "analytics"
      }
    ]
  }
}
```

**Field Explanations**:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Warehouse name | `"Production SQL Warehouse"` |
| `cluster_size` | Yes | Warehouse size | `"2X-Small"`, `"X-Small"`, `"Small"`, `"Medium"`, `"Large"`, `"X-Large"`, `"2X-Large"`, `"3X-Large"`, `"4X-Large"` |
| `min_num_clusters` | No | Min clusters | `1` |
| `max_num_clusters` | No | Max clusters | `3` |
| `auto_stop_mins` | No | Auto-stop minutes | `20` |
| `spot_instance_policy` | No | Spot instance policy | `"COST_OPTIMIZED"`, `"RELIABILITY_OPTIMIZED"` |
| `warehouse_type` | No | Warehouse type | `"PRO"`, `"CLASSIC"` |
| `enable_photon` | No | Enable Photon | `true` |
| `enable_serverless_compute` | No | Enable serverless | `true` |

**Cluster Size Guide**:
- `2X-Small` - 1 DBU, 2 cores
- `X-Small` - 2 DBU, 4 cores
- `Small` - 4 DBU, 8 cores
- `Medium` - 8 DBU, 16 cores
- `Large` - 16 DBU, 32 cores

**Best Practices**:
- Use `PRO` type for production
- Enable Photon for better performance
- Use serverless for variable workloads
- Set auto-stop to save costs
- Start with `Small` or `Medium` size

---

## Common Patterns

### Dynamic References

Reference other module outputs in your JSON files:

**Access Connector**:
```json
"access_connector_id": "${module.access_connectors[\"ac-name\"].id}"
"access_connector_principal_id": "${module.access_connectors[\"ac-name\"].principal_id}"
```

**Workspace**:
```json
"workspace_id": "${module.workspaces[\"workspace-name\"].workspace_id}"
"subnet_id": "${module.workspaces[\"workspace-name\"].subnet_ids[\"subnet-name\"]}"
"vnet_id": "${module.workspaces[\"workspace-name\"].vnet_id}"
```

**Storage Account**:
```json
"storage_account_id": "${module.storage_accounts[\"storage-name\"].id}"
```

**Metastore**:
```json
"metastore_id": "${module.metastores[\"metastore-name\"].metastore_id}"
```

### Enable/Disable Resources

Control resource creation with the `enabled` flag:

```json
{
  "enabled": false,
  "name": "my-resource"
}
```

### Workspace Binding

Bind Unity Catalog resources to specific workspaces:

```json
{
  "name": "my-catalog",
  "workspace_ids": [
    "${module.workspaces[\"workspace1\"].workspace_id}",
    "${module.workspaces[\"workspace2\"].workspace_id}"
  ]
}
```

---

## Troubleshooting

### Common Issues

**Issue**: "Storage account name must be globally unique"
**Solution**: Change storage account name to something unique

**Issue**: "Access Connector not found"
**Solution**: Ensure access connector is created before storage account

**Issue**: "Subnet delegation conflict"
**Solution**: Don't manually delegate subnets; the module handles it

**Issue**: "Private endpoint network policies must be disabled"
**Solution**: Set `private_endpoint_network_policies: "Disabled"` on PE subnets

**Issue**: "DNS zone already exists"
**Solution**: Use existing DNS zone ID instead of auto-create

**Issue**: "Workspace not found for metastore assignment"
**Solution**: Ensure workspace is created before assignment

**Issue**: "Service principal not workspace admin"
**Solution**: Use workspace admin assignment module or manually add SP

---

## Deployment Workflow

### Step-by-Step Deployment

1. **Initialize Terraform**:
```bash
terraform init
```

2. **Create Resource Group and Access Connector**:
```bash
# Create JSON files
resources/azure/resource_groups/my-rg.json
resources/azure/access_connectors/my-ac.json

# Plan and apply
terraform plan
terraform apply
```

3. **Create Workspace**:
```bash
# Create JSON file
resources/azure/workspaces/my-workspace.json

# Plan and apply
terraform plan
terraform apply
```

4. **Create Storage Account**:
```bash
# Create JSON file
resources/azure/storage_accounts/my-storage.json

# Plan and apply
terraform plan
terraform apply
```

5. **Create Metastore and Assignment**:
```bash
# Create JSON files
resources/databricks/account/metastores/my-metastore.json
resources/databricks/account/metastore_assignments/my-assignment.json

# Plan and apply
terraform plan
terraform apply
```

6. **Create Workspace Objects**:
```bash
# Create JSON files for storage credentials, external locations, catalogs, etc.

# Plan and apply
terraform plan
terraform apply
```

### Validation

After each phase, validate:

1. **Azure Portal**: Check resources are created
2. **Databricks Workspace**: Check workspace is accessible
3. **Unity Catalog**: Check metastore is assigned
4. **Catalogs**: Check catalogs and schemas are created


