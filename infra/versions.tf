terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113" # or latest 3.x
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
