variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID for account-level operations"
  default     = ""
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks Account Console URL (e.g., https://accounts.azuredatabricks.net)"
  default     = "https://accounts.azuredatabricks.net"
}


variable "databricks_workspace_host" {
  type        = string
  description = "Databricks Workspace URL (e.g., https://adb-xxx.azuredatabricks.net)"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "default_location" {
  type        = string
  description = "Default Azure region for resources"
  default     = "eastus"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all resources"
  default = {
    ManagedBy = "Terraform"
    Project   = "Databricks-Deployment"
  }
}

variable "resource_groups" {
  type        = map(any)
  description = "Map of resource group configurations"
  default     = {}
}

variable "workspaces" {
  type        = map(any)
  description = "Map of Databricks workspace configurations"
  default     = {}
}

variable "storage_accounts" {
  type        = map(any)
  description = "Map of storage account configurations"
  default     = {}
}

variable "key_vaults" {
  type        = map(any)
  description = "Map of Key Vault configurations"
  default     = {}
}

variable "data_factories" {
  type        = map(any)
  description = "Map of Data Factory configurations"
  default     = {}
}

variable "vms" {
  type        = map(any)
  description = "Map of Virtual Machine configurations"
  default     = {}
}

variable "vnets" {
  type        = map(any)
  description = "Map of Virtual Network configurations"
  default     = {}
}

variable "access_connectors" {
  type        = map(any)
  description = "Map of Databricks Access Connector configurations"
  default     = {}
}

variable "metastores" {
  type        = map(any)
  description = "Map of Unity Catalog metastore configurations"
  default     = {}
}

variable "metastore_assignments" {
  type        = map(any)
  description = "Map of metastore assignment configurations"
  default     = {}
}

variable "storage_credentials" {
  type        = map(any)
  description = "Map of storage credential configurations"
  default     = {}
}

variable "external_locations" {
  type        = map(any)
  description = "Map of external location configurations"
  default     = {}
}

variable "catalogs" {
  type        = map(any)
  description = "Map of catalog configurations"
  default     = {}
}

variable "schemas" {
  type        = map(any)
  description = "Map of schema configurations"
  default     = {}
}

variable "clusters" {
  type        = map(any)
  description = "Map of cluster configurations"
  default     = {}
}

variable "cluster_policies" {
  type        = map(any)
  description = "Map of cluster policy configurations"
  default     = {}
}

variable "sql_warehouses" {
  type        = map(any)
  description = "Map of SQL warehouse configurations"
  default     = {}
}

variable "workspace_folders" {
  type        = map(any)
  description = "Map of workspace folder configurations"
  default     = {}
}

variable "queries" {
  type        = map(any)
  description = "Map of SQL query configurations"
  default     = {}
}

variable "alerts" {
  type        = map(any)
  description = "Map of alert configurations"
  default     = {}
}

variable "budget_policies" {
  type        = map(any)
  description = "Map of budget policy configurations"
  default     = {}
}

variable "ncc_configs" {
  type        = map(any)
  description = "Map of Network Connectivity Configuration settings"
  default     = {}
}

variable "ncc_private_endpoints" {
  type        = map(any)
  description = "Map of NCC Private Endpoint Rule settings"
  default     = {}
}

variable "service_principals" {
  type        = map(any)
  description = "Map of service principal configurations"
  default     = {}
}

variable "workspace_permissions" {
  type        = map(any)
  description = "Map of workspace permission configurations"
  default     = {}
}

variable "workspace_admin_assignments" {
  type        = map(any)
  description = "Map of workspace admin assignment configurations for account-level service principals"
  default     = {}
}

