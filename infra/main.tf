############################################
# Resource Group, LA Workspace, Container Apps Env
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
# Container App (API)
############################################
resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single" # or "Multiple"

  identity { type = "SystemAssigned" }

  # Registry using ACR admin creds (quick start)
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-pwd"
  }

  # ---- Secrets live at the top level
  secret {
    name  = "acr-pwd"
    value = azurerm_container_registry.acr.admin_password
  }

  secret {
    name  = "openai-key"
    value = var.openai_api_key
  }

  # ---- Pod template
  template {
    container {
      name   = "api"
      image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env { name = "OPENAI_MODEL"   value       = var.openai_model }
      env { name = "OPENAI_API_KEY" secret_name = "openai-key"     }
    }

    # use these; there is no separate 'scale' block
    min_replicas = 1
    max_replicas = 2
  }

  # ---- Ingress requires at least one traffic_weight
  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

output "api_fqdn" {
  value = azurerm_container_app.api.latest_revision_fqdn
}
