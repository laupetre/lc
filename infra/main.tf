############################################
# Providers
############################################
provider "azurerm" {
  features {}
}

# (optional) used to call listSecrets on the Static Web App
provider "azapi" {}

############################################
# Resource Group
############################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

############################################
# Azure Container Registry (ACR)
############################################
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

############################################
# Log Analytics + Container Apps Environment
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

  # Public ingress
  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Template / container definition
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

      # This references the top-level secret declared below
      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-key"
      }
    }
  }

  # ACR registry reference with credentials via secret
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-pwd"
  }

  # ✅ Top-level secrets (NOT inside template)
  # OpenAI key for the app
  secret {
    name  = "openai-key"
    value = var.openai_api_key
  }

  # ACR admin password for registry auth
  secret {
    name  = "acr-pwd"
    value = azurerm_container_registry.acr.admin_password
  }
}

############################################
# Static Web App (new resource, not deprecated)
# Must be deployed in a supported region (e.g., eastus2)
############################################
resource "azurerm_static_web_app" "swa" {
  name                = "lc-swa-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.swa_location

  sku_tier = "Free"
  sku_size = "Free"
}

# Retrieve the deployment token for SWA (used by GitHub Actions)
resource "azapi_resource_action" "swa_secrets" {
  type                   = "Microsoft.Web/staticSites@2022-03-01"
  resource_id            = azurerm_static_web_app.swa.id
  action                 = "listSecrets"
  method                 = "POST"
  # We return the properties object so we can access properties.apiKey directly
  response_export_values = ["properties"]
}
