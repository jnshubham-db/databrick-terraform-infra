terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.85.0"
    }
  }
}

