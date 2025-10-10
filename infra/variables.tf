variable "location" {
  type        = string
  description = "Azure location"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for all resources"
  default     = "lc-swa-rg"
}

variable "acr_name" {
  type        = string
  description = "Azure Container Registry name"
  default     = "lcacrio"
}

variable "containerapps_env_name" {
  type        = string
  description = "Azure Container Apps environment name"
  default     = "lc-swa-env"
}

variable "containerapp_name" {
  type        = string
  description = "Container App name"
  default     = "lc-swa-api"
}

variable "image_name" {
  type        = string
  description = "Image repo name inside ACR"
  default     = "lc-swa-api"
}

variable "image_tag" {
  type        = string
  description = "Image tag"
  default     = "latest"
}

variable "container_port" {
  type        = number
  description = "Container exposed port"
  default     = 8000
}

variable "openai_model" {
  type        = string
  description = "OpenAI model"
  default     = "gpt-4o-mini"
}

variable "openai_api_key" {
  type        = string
  description = "OpenAI API key"
  sensitive   = true
  default     = null
}

# NEW: allow explicit SP credentials to be passed to azapi (fallback to CLI)
variable "arm_client_id"       { type = string, default = null }
variable "arm_client_secret"   { type = string, default = null, sensitive = true }
variable "arm_tenant_id"       { type = string, default = null }
variable "arm_subscription_id" { type = string, default = null }
