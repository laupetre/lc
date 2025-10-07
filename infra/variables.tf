variable "location"               { type = string  default = "eastus" }
variable "resource_group_name"    { type = string  default = "lc-swa-rg" }
variable "acr_name"               { type = string  default = "lcacrio" }   # must be globally unique, alphanumeric only
variable "containerapps_env_name" { type = string  default = "lc-swa-env" }
variable "containerapp_name"      { type = string  default = "lc-swa-api" }
variable "swa_name"               { type = string  default = "lc-swa-web" }
variable "openai_model"           { type = string  default = "gpt-4o-mini" }
variable "openai_api_key"         { type = string  sensitive = true }

# Image the CI will build and push to ACR
variable "image_name"             { type = string  default = "lc-swa-api" }
variable "image_tag"              { type = string  default = "latest" }
variable "container_port"         { type = number  default = 8000 }
