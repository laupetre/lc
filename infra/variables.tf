variable "location"          { type = string, default = "eastus" }
variable "resource_group_name" { type = string, default = "lc-swa-rg" }

variable "acr_name"                { type = string, default = "lcacrio" }
variable "containerapps_env_name"  { type = string, default = "lc-swa-env" }
variable "containerapp_name"       { type = string, default = "lc-swa-api" }

variable "image_name" { type = string, default = "lc-swa-api" }
variable "image_tag"  { type = string, default = "latest" }
variable "container_port" { type = number, default = 8000 }

variable "openai_model"   { type = string,  default = "gpt-4o-mini" }
variable "openai_api_key" { type = string,  sensitive = true }
