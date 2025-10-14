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
  name                = var.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################################
# User-Assigned Managed Identity (for ACR pull)
############################################
resource "azurerm_user_assigned_identity" "pull_mi" {
  name                = "${var.containerapp_name}-mi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Grant MI permission to pull images from ACR
resource "azurerm_role_assignment" "mi_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.pull_mi.principal_id
}

############################################
# Container Apps Environment (ACA)
############################################
resource "azurerm_container_app_environment" "env" {
  name                       = var.containerapps_env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  timeouts {
    create = "60m"
    update = "60m"
  }
}

############################################
# Container App (API)
############################################
resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  # Pull image from ACR using the user-assigned MI
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.pull_mi.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.pull_mi.id
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "api"
      image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "OPENAI_MODEL"
        value = var.openai_model
      }

      dynamic "env" {
        for_each = var.openai_api_key == null || var.openai_api_key == "" ? [] : [1]
        content {
          name  = "OPENAI_API_KEY"
          value = var.openai_api_key
        }
      }
    }
  }

  tags = {
    app = var.containerapp_name
  }

  timeouts {
    create = "60m"
    update = "60m"
  }
}

############################################
# Static Web App (must be in supported region)
############################################
resource "azurerm_static_web_app" "swa" {
  name                = var.swa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_tier            = "Free"
  sku_size            = "Free"
}

# Fetch SWA deployment token
resource "azapi_resource_action" "swa_secrets" {
  type                   = "Microsoft.Web/staticSites@2022-03-01"
  resource_id            = azurerm_static_web_app.swa.id
  action                 = "listSecrets"
  method                 = "POST"
  response_export_values = ["properties"]
}
