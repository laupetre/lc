############################################
# Provider
############################################
provider "azurerm" {
  features {}
}

############################################
# Resource Group
############################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

############################################
# ACR
############################################
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

############################################
# Log Analytics & Container Apps Environment
############################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${azurerm_resource_group.rg.name}-law"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = var.containerapps_env_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

############################################
# Container App (API)
############################################
resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      percentage       = 100
      latest_revision  = true
    }
  }

  template {
    container {
      name   = "api"
      image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "OPENAI_MODEL"
        value = var.openai_model
      }

      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-key"
      }
    }

    secret {
      name  = "openai-key"
      value = var.openai_api_key
    }
  }

  registry {
    server = azurerm_container_registry.acr.login_server
  }
}

############################################
# Static Web App (use the new resource)
############################################
# NOTE: Static Web Apps are not available in `eastus` – use one of:
# westus2, centralus, eastus2, westeurope, eastasia
resource "azurerm_static_web_app" "swa" {
  name                = "lc-swa-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.swa_location

  sku_tier = "Free"
  sku_size = "Free"
}

# Fetch deployment token for SWA (needed by GitHub Actions to deploy)
# We call listSecrets on the static web app.
resource "azapi_resource_action" "swa_secrets" {
  type                   = "Microsoft.Web/staticSites@2022-03-01"
  resource_id            = azurerm_static_web_app.swa.id
  action                 = "listSecrets"
  method                 = "POST"
  response_export_values = ["properties.apiKey"]
}
