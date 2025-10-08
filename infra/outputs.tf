# API
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

# --- NEW: SWA outputs ---
output "swa_default_hostname" {
  value = azurerm_static_site.swa.default_host_name
}

output "swa_name" {
  value = azurerm_static_site.swa.name
}

output "swa_token" {
  value     = azapi_resource_action.swa_secrets.output.properties.apiKey
  sensitive = true
}
