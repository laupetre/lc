terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
  }

  # Single backend declaration (init values are supplied via -backend-config in CI)
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
