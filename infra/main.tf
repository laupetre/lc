############################################
# Resource Group, Log Analytics, Container Apps Env
############################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.resource_group_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = var.containerapps_env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

############################################
# ACR (admin enabled for simplicity)
############################################
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  admin_enabled       = true
}

############################################
# Container App (API) — seeded with public image
############################################
resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  identity { type = "SystemAssigned" }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-pwd"
  }

  secret {
    name  = "acr-pwd"
    value = azurerm_container_registry.acr.admin_password
  }

  secret {
    name  = "openai-key"
    value = var.openai_api_key
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
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

    min_replicas = 1
    max_replicas = 2
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

############################################
# --- NEW: Static Web App (classic) + listSecrets token
############################################
# Create Static Web App (no repo connection; we deploy with token)
resource "azurerm_static_site" "swa" {
  name                = var.swa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_tier            = "Free"
  # Optional custom domains etc. can be added later
}

# Query its secrets to get the deployment API token
resource "azapi_resource_action" "swa_secrets" {
  type        = "Microsoft.Web/staticSites@2022-09-01"
  resource_id = azurerm_static_site.swa.id
  action      = "listSecrets"
  method      = "POST"

  response_export_values = ["properties.apiKey"]
}
