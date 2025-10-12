############################################
# General settings
############################################

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group for the stack"
  type        = string
  default     = "lc-swa-rg"
}

variable "acr_name" {
  description = "Azure Container Registry name (lowercase, 5-50 chars)"
  type        = string
  default     = "lcacrio"
}

variable "containerapps_env_name" {
  description = "Azure Container Apps Environment name"
  type        = string
  default     = "lc-swa-env"
}

variable "containerapp_name" {
  description = "Container App (API) name"
  type        = string
  default     = "lc-swa-api"
}

variable "image_name" {
  description = "Base image name to use/push in ACR"
  type        = string
  default     = "lc-swa-api"
}

variable "image_tag" {
  description = "Image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Container port exposed by the API"
  type        = number
  default     = 8000
}

variable "openai_model" {
  description = "Default OpenAI model to use"
  type        = string
  default     = "gpt-4o-mini"
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
  default     = null
}

############################################
# Optional ARM credentials (you are using OIDC now,
# so these can remain null)
############################################

variable "arm_client_id" {
  type    = string
  default = null
}

variable "arm_client_secret" {
  type      = string
  default   = null
  sensitive = true
}

variable "arm_tenant_id" {
  type    = string
  default = null
}

variable "arm_subscription_id" {
  type    = string
  default = null
}

############################################
# Static Web App
############################################

variable "swa_name" {
  description = "Static Web App name"
  type        = string
  default     = "lc-swa-web"
}
