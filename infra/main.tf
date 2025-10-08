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

  # Managed Identity (also useful for AcrPull if you switch from admin creds)
  identity {
    type = "SystemAssigned"
  }

  # Registry configuration (kept here for when the workflow switches to ACR image)
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-pwd"
  }

  # Secrets live at the top level
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
      name = "api"

      # Seed with a public image so creation doesn't depend on ACR having your tag yet
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

    # Replace old 'scale' block with these
    min_replicas = 1
    max_replicas = 2
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    # At least one traffic_weight is required
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

############################################
# Useful outputs (API URL/FQDN and ACR login server)
############################################
output "api_hostname" {
  description = "Container App public host name"
  value       = azurerm_container_app.api.latest_revision_fqdn
}

output "api_url" {
  description = "Container App public URL"
  value       = "https://${azurerm_container_app.api.latest_revision_fqdn}"
}

output "container_app_id" {
  value = azurerm_container_app.api.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
