locals {
  tags = {
    project     = var.project
    env         = var.environment
    iac         = "terraform"
  }
  
  # Only create Box secrets if values are provided
  has_box_config = var.box_client_id != "" && var.box_client_secret != "" && var.box_access_token != ""
  
  # Environment-aware resource names
  resource_group_name      = "${var.project}-${var.environment}-rg"
  acr_name                 = "${var.acr_name}${var.environment}"
  containerapp_env_name    = "${var.project}-${var.environment}-env"
  containerapp_name        = "${var.project}-${var.environment}-api"
  swa_name                 = "${var.project}-${var.environment}-frontend"
  log_analytics_name       = "${var.project}-${var.environment}-env-logs"
  managed_identity_name    = "${var.project}-${var.environment}-api-mi"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  # Enable admin access for simpler authentication
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_static_web_app" "swa" {
  name                = local.swa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = "East US 2"
  sku_tier            = "Free"
  tags                = local.tags
}

resource "azurerm_log_analytics_workspace" "env" {
  name                = local.log_analytics_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_container_app_environment" "env" {
  name                       = local.containerapp_env_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.env.id
  tags                       = local.tags
}

resource "azurerm_user_assigned_identity" "api" {
  name                = local.managed_identity_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_container_app" "api" {
  name                         = local.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api.id]
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "OPENAI_MODEL"
        value = var.openai_model
      }

      env {
        name  = "ALLOWED_ORIGIN"
        value = "https://${azurerm_static_web_app.swa.default_host_name}"
      }

      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-api-key"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  secret {
    name  = "openai-api-key"
    value = var.openai_api_key
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  # Box integration secrets (optional - only if configured)
  dynamic "secret" {
    for_each = local.has_box_config ? [1] : []
    content {
      name  = "box-client-id"
      value = var.box_client_id
    }
  }
  dynamic "secret" {
    for_each = local.has_box_config ? [1] : []
    content {
      name  = "box-client-secret"
      value = var.box_client_secret
    }
  }
  dynamic "secret" {
    for_each = local.has_box_config ? [1] : []
    content {
      name  = "box-access-token"
      value = var.box_access_token
    }
  }

  tags = local.tags
}

# Azure AD OAuth app registration for Static Web App authentication
# Commented out due to insufficient permissions in GitHub Actions
# Create app registration manually in Azure Portal if needed
# resource "azuread_application" "swa_oauth" {
#   display_name     = "${var.project}-oauth-app"
#   sign_in_audience = "AzureADMyOrg"
#   
#   web {
#     redirect_uris = [
#       "https://${azurerm_static_web_app.swa.default_host_name}/.auth/login/aad/callback"
#     ]
#   }
#
#   required_resource_access {
#     resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
#     
#     resource_access {
#       id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
#       type = "Scope"
#     }
#   }
#
#   owners = [data.azurerm_client_config.current.object_id]
# }
#
# # Create a password credential (client secret) for the app
# resource "azuread_application_password" "swa_oauth" {
#   application_id = azuread_application.swa_oauth.id
#   display_name   = "Static Web App OAuth Secret"
#   
#   # Set expiration to 1 year from now
#   end_date = timeadd(timestamp(), "8760h")
# }

# Azure AD resources for GitHub Actions OIDC (commented out due to permission issues)
# resource "azuread_application" "gha" {
#   display_name = "${var.project}-gha-oidc"
#   owners       = [data.azurerm_client_config.current.object_id]
# }

# resource "azuread_service_principal" "gha" {
#   client_id = azuread_application.gha.client_id
#   owners    = [data.azurerm_client_config.current.object_id]
# }

# resource "azurerm_role_assignment" "gha_contrib" {
#   scope                = azurerm_resource_group.rg.id
#   role_definition_name = "Contributor"
#   principal_id         = azuread_service_principal.gha.object_id
# }

# resource "azurerm_role_assignment" "gha_user_admin" {
#   scope                = azurerm_resource_group.rg.id
#   role_definition_name = "User Access Administrator"
#   principal_id         = azuread_service_principal.gha.object_id
# }

# resource "azuread_application_federated_identity_credential" "gha_fic_branch" {
#   application_id = azuread_application.gha.id
#   display_name   = "github-${var.github_org}-${var.github_repo}-${var.github_branch}"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
#   subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
# }
