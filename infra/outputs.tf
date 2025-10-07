output "api_url" {
  description = "Public URL of the Container App"
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "swa_url" {
  description = "Static Web App default URL"
  value       = "https://${azurerm_static_web_app.swa.default_host_name}"
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

# Deployment token used by Azure/static-web-apps-deploy@v1
output "swa_deployment_token" {
  description = "SWA deployment token (mask & store as needed)"
  value       = jsondecode(azapi_resource_action.swa_secrets.output).properties.apiKey
  sensitive   = true
}
