# ----------------------
# Resource Group
# ----------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ----------------------
# Log Analytics (for Container Apps env)
# ----------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.resource_group_name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

# ----------------------
# Container Apps Environment
# ----------------------
resource "azurerm_container_app_environment" "cenv" {
  name                       = var.containerapps_env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

# ----------------------
# Azure Container Registry
# ----------------------
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku           = "Basic"
  admin_enabled = false
}

# ----------------------
# User-Assigned Managed Identity for the Container App (to pull from ACR)
# ----------------------
resource "azurerm_user_assigned_identity" "api_mi" {
  name                = "${var.containerapp_name}-mi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow that identity to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api_mi.principal_id
}

# ----------------------
# Static Web App
# ----------------------
resource "azurerm_static_web_app" "swa" {
  name                = var.swa_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Optional: you can wire repo here, but your GitHub Action already deploys the built site
  # repository_url  = "https://github.com/you/your-repo"
  # branch          = "main"
  # sku_tier        = "Free"
}

# ----------------------
# Container App (API)
# ----------------------
resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cenv.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api_mi.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.api_mi.id
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
    transport        = "auto"
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

      # lock CORS to the SWA host (the hostname becomes available after SWA is created)
      env {
        name  = "ALLOWED_ORIGIN"
        value = "https://${azurerm_static_web_app.swa.default_host_name}"
      }

      # reference the secret for OPENAI_API_KEY at runtime
      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-key"
      }
    }

    secret {
      name  = "openai-key"
      value = var.openai_api_key
    }

    scale {
      min_replicas = 0
      max_replicas = 3
    }
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}

# ----------------------
# Fetch SWA deployment token (for your GitHub Action)
# ----------------------
data "azurerm_client_config" "current" {}
# Call ARM action 'listSecrets' via azapi to get the deployment token (apiKey)
resource "azapi_resource_action" "swa_secrets" {
  type        = "Microsoft.Web/staticSites@2022-03-01"
  resource_id = azurerm_static_web_app.swa.id
  action      = "listSecrets"
  method      = "POST"

  response_export_values = ["properties"]
}
