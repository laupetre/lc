terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.114.0" }
    azuread = { source = "hashicorp/azuread", version = ">= 2.53.1" }
    local   = { source = "hashicorp/local",   version = ">= 2.5.1" }
  }
}
