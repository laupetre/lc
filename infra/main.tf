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
  admin_enabled       = false
}

############################################
# Log Analytics
############################################

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.resource_group_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################################
# Container Apps Environment
############################################

resource "azurerm_container_app_environment" "env" {
  name                       = var.containerapps_env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
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

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = "System"
  }

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      percentage = 100
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

      # Optional: wire secret from SWA token if you want to call it from API, etc.
    }
  }
}

############################################
# Static Web App
############################################

resource "azurerm_static_web_app" "swa" {
  name                = var.swa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

############################################
# SWA: get deployment token with AZAPI (requires AAD auth via runner)
############################################

resource "azapi_resource_action" "swa_secrets" {
  # Lists secrets for SWA (API 2022-03-01)
  type        = "Microsoft.Web/staticSites@2022-03-01"
  resource_id = azurerm_static_web_app.swa.id
  action      = "listSecrets"
  method      = "POST"
}

