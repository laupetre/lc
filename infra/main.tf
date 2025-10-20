locals {
  tags = { project = var.project, env = "prod", iac = "terraform" }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

resource "azurerm_static_web_app" "swa" {
  name                = var.swa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_tier            = "Free"
  tags                = local.tags
}

resource "azurerm_container_app_environment" "env" {
  name                = var.containerapp_env_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "api" {
  name                = "${var.containerapp_name}-mi"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

resource "azurerm_container_app" "api" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.api.id
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

      env { name = "OPENAI_MODEL"   value = var.openai_model }
      env { name = "ALLOWED_ORIGIN" value = "https://${azurerm_static_web_app.swa.default_host_name}" }
      env { name = "OPENAI_API_KEY" secret_name = "openai-api-key" }
    }

    min_replicas = 1
    max_replicas = 3
  }

  secret { name = "openai-api-key"; value = var.openai_api_key }

  tags = local.tags

  depends_on = [ azurerm_role_assignment.acr_pull ]
}

resource "azuread_application" "gha" {
  display_name = "${var.project}-gha-oidc"
}

resource "azuread_service_principal" "gha" {
  application_id = azuread_application.gha.application_id
}

resource "azurerm_role_assignment" "gha_contrib" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.gha.object_id
}

resource "azuread_application_federated_identity_credential" "gha_fic_branch" {
  application_object_id = azuread_application.gha.object_id
  display_name          = "github-${var.github_org}-${var.github_repo}-${var.github_branch}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

resource "local_file" "aca_fqdn_file" {
  content  = azurerm_container_app.api.latest_revision_fqdn
  filename = "${path.module}/.aca_fqdn.txt"
}

resource "null_resource" "post_apply_note" {
  triggers = {
    aca_fqdn = azurerm_container_app.api.latest_revision_fqdn
    swa_host = azurerm_static_web_app.swa.default_host_name
    acr_srv  = azurerm_container_registry.acr.login_server
    clientid = azuread_service_principal.gha.application_id
    tenant   = data.azurerm_client_config.current.tenant_id
    sub      = data.azurerm_client_config.current.subscription_id
  }

  provisioner "local-exec" {
    command = <<EOT
echo "=== Deploy Info ==="
echo "ACA FQDN: ${self.triggers.aca_fqdn}"
echo "SWA Host: ${self.triggers.swa_host}"
echo "ACR:      ${self.triggers.acr_srv}"
echo "GH OIDC Client ID: ${self.triggers.clientid}"
echo "Tenant:   ${self.triggers.tenant}"
echo "Sub:      ${self.triggers.sub}"
echo ""
echo "Repo secrets to set:"
echo "  AZURE_SUBSCRIPTION_ID=${self.triggers.sub}"
echo "  AZURE_TENANT_ID=${self.triggers.tenant}"
echo "  AZURE_CLIENT_ID=${self.triggers.clientid}"
echo "  OPENAI_API_KEY=<your key>"
echo "  SWA_DEPLOYMENT_TOKEN=<from SWA resource>"
EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [ local_file.aca_fqdn_file ]
}
