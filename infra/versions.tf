terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.114.0" }
    azuread = { source = "hashicorp/azuread", version = ">= 2.53.1" }
    random  = { source = "hashicorp/random",  version = ">= 3.6.0" }
    null    = { source = "hashicorp/null",    version = ">= 3.2.2" }
    local   = { source = "hashicorp/local",   version = ">= 2.5.1" }
  }
}
