terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.14"
    }
  }

  backend "azurerm" {}
}

# --- Providers (UPDATED) ---

provider "azurerm" {
  features {}
}

# Prefer Azure CLI creds (from azure/login); if SP vars are provided, use them.
provider "azapi" {
  use_cli         = true
  client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret
  tenant_id       = var.arm_tenant_id
  subscription_id = var.arm_subscription_id
}

# --- Resources (unchanged from your working configuration) ---

# Resource group (if you manage it in TF)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ACR
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

# Log Analytics
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.resource_group_name}-law"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = var.containerapps_env_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

# Static Web App (for token)
resource "azurerm_static_web_app" "swa" {
  name                = "lc-swa-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus2"
  sku_tier            = "Standard"
  sku_size            = "Standard"
}

# Call SWA listSecrets via azapi
resource "azapi_resource_action" "swa_secrets" {
  type        = "Microsoft.Web/staticSites@2022-03-01"
  resource_id = azurerm_static_web_app.swa.id
  action      = "listSecrets"
  method      = "POST"
  depends_on  = [azurerm_static_web_app.swa]
}

# Container App using ACR + MI pull
resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  workload_profile_name        = "Consumption"

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = "system"
  }

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
    traffic_weight {
      weight = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = var.containerapp_name
      image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "OPENAI_MODEL"
        value = var.openai_model
      }
      env {
        name  = "OPENAI_API_KEY"
        value = var.openai_api_key
      }
    }
  }
}
