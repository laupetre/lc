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
