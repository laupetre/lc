output "api_hostname" {
  description = "Latest revision FQDN for the Container App"
  value       = try(azurerm_container_app.api.latest_revision_fqdn, null)
}

output "api_url" {
  description = "Public URL for the API"
  value       = try("https://${azurerm_container_app.api.latest_revision_fqdn}", null)
}

output "container_app_id" {
  description = "Resource ID of the Container App"
  value       = azurerm_container_app.api.id
}

output "acr_login_server" {
  description = "ACR login server (e.g., lcacrio.azurecr.io)"
  value       = azurerm_container_registry.acr.login_server
}

output "swa_token" {
  description = "Static Web App deployment token"
  value       = try(jsondecode(azapi_resource_action.swa_secrets.output).properties.apiKey, null)
  sensitive   = true
}
