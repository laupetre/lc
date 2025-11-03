output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aca_fqdn" {
  value = azurerm_container_app.api.latest_revision_fqdn
}

output "swa_default_hostname" {
  value = azurerm_static_web_app.swa.default_host_name
}

# output "github_client_id" {
#   value = azuread_service_principal.gha.client_id
# }

output "azure_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

# OAuth App Registration outputs (commented out - create app registration manually in Azure Portal)
# output "oauth_client_id" {
#   value       = azuread_application.swa_oauth.client_id
#   description = "Application (client) ID for Static Web App OAuth authentication"
# }
#
# output "oauth_client_secret" {
#   value       = azuread_application_password.swa_oauth.value
#   sensitive   = true
#   description = "Client secret for Static Web App OAuth authentication - add this to Static Web App configuration as MICROSOFT_CLIENT_SECRET"
# }

output "oauth_redirect_uri" {
  value       = "https://${azurerm_static_web_app.swa.default_host_name}/.auth/login/aad/callback"
  description = "OAuth redirect URI to use when creating the app registration manually"
}
