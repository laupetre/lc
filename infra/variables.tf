variable "project" {
  type    = string
  default = "lc-swa"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = "lc-swa-rg"
}

variable "acr_name" {
  type    = string
  default = "lcacrio"
}

variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "openai_model" {
  type    = string
  default = "gpt-4o-mini"
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "containerapp_env_name" {
  type    = string
  default = "lc-swa-env"
}

variable "containerapp_name" {
  type    = string
  default = "lc-swa-api"
}

variable "swa_name" {
  type    = string
  default = "lc-swa-frontend"
}

variable "use_existing_resources" {
  type        = bool
  default     = false
  description = "If true, will try to import existing resources instead of creating new ones"
}

variable "box_client_id" {
  type        = string
  default     = ""
  description = "Box API Client ID (optional)"
  sensitive   = true
}

variable "box_client_secret" {
  type        = string
  default     = ""
  description = "Box API Client Secret (optional)"
  sensitive   = true
}

variable "box_access_token" {
  type        = string
  default     = ""
  description = "Box API Access Token (optional)"
  sensitive   = true
}
