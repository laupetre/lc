############################################
# General settings
############################################

variable "location" {
  description = "Azure region (SWA supported regions include eastus2, centralus, westus2, westeurope, eastasia)"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group for the stack"
  type        = string
  default     = "lc-swa-rg"
}

variable "acr_name" {
  description = "Azure Container Registry name (lowercase 5-50 chars)"
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
  description = "Image repo name in ACR"
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
  description = "Default OpenAI model"
  type        = string
  default     = "gpt-4o-mini"
}

variable "openai_api_key" {
  description = "OpenAI API Key (optionally injected)"
  type        = string
  sensitive   = true
  default     = null
}

variable "law_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "lc-swa-rg-law"
}

variable "swa_name" {
  description = "Static Web App name"
  type        = string
  default     = "lc-swa-web"
}
