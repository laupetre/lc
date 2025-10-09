output "api_hostname" {
  value       = azurerm_container_app.api.ingress[0].fqdn
  description = "FQDN of the API Container App."
}

output "api_url" {
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
  description = "Public URL of the API."
}

output "container_app_id" {
  value       = azurerm_container_app.api.id
  description = "Resource ID of the API Container App."
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "Login server for ACR (e.g., myacr.azurecr.io)."
}

output "swa_url" {
  value       = "https://${azurerm_static_web_app.swa.default_host_name}"
  description = "Public URL of the Static Web App."
}

output "swa_token" {
  # azapi returns: {"properties":{"apiKey":"<token>"}}
  value       = jsondecode(azapi_resource_action.swa_secrets.output).properties.apiKey
  sensitive   = true
  description = "Deployment token for Static Web App."
}
