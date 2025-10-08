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
