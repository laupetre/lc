############################################
# providers / versions
############################################
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
  }

  # remote state is configured from the workflow with -backend-config
  backend "azurerm" {}
}

provider "azurerm" { features {} }

############################################
# variables (must exist in variables.tf)
# - location
# - resource_group_name
# - acr_name
# - containerapps_env_name
# - containerapp_name
# - image_name
# - image_tag
# - container_port
# - openai_model
# - openai_api_key (sensitive)
############################################

############################################
# RG + Log Analytics + Container Apps Env
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
  revision_mode                = "Single" # "Multiple" also fine

  identity {
    type = "SystemAssigned"
  }

  # ---- Registry auth (using ACR admin creds)
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-pwd"
  }

  # ---- Secrets live at the top level (NOT inside template)
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

      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-key"
      }

      env {
        name  = "OPENAI_MODEL"
        value = var.openai_model
      }
    }

    # use these instead of an old `scale {}` block
    min_replicas = 1
    max_replicas = 2
  }

  # ---- Ingress must include at least one traffic_weight
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
