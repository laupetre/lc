terraform {
  required_version = ">= 1.4.0"

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

  # Backend details are passed from the workflow via -backend-config
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
