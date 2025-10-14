terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
  }

  # Backend is configured from your GitHub Actions with -backend-config
  backend "azurerm" {}
}

# Providers (centralized here only)
provider "azurerm" {
  features {}
}

# With OIDC env (ARM_USE_OIDC/ARM_*), azapi will auth automatically
provider "azapi" {}
