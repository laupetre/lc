variable "location" {
  type        = string
  default     = "eastus"
  description = "Primary Azure location for Container Apps, ACR, Log Analytics, etc."
}

variable "swa_location" {
  type        = string
  default     = "eastus2"
  description = "Location for Azure Static Web App (must be one of: westus2, centralus, eastus2, westeurope, eastasia)."
}

variable "resource_group_name" {
  type        = string
  default     = "lc-swa-rg"
}

variable "acr_name" {
  type        = string
  default     = "lcacrio"
}

variable "containerapps_env_name" {
  type        = string
  default     = "lc-swa-env"
}

variable "containerapp_name" {
  type        = string
  default     = "lc-swa-api"
}

variable "image_name" {
  type        = string
  default     = "lc-swa-api"
}

variable "image_tag" {
  type        = string
  default     = "latest"
}

variable "container_port" {
  type        = number
  default     = 8000
}

variable "openai_model" {
  type        = string
  default     = "gpt-4o-mini"
}

variable "openai_api_key" {
  type        = string
  sensitive   = true
  description = "OpenAI API key injected into the API container as a secret."
}

# (If you already have variables for ACR admin/password or other optional knobs, keep them as-is.)
