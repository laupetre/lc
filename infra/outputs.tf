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

output "github_client_id" {
  value = azuread_service_principal.gha.client_id
}

output "azure_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}
