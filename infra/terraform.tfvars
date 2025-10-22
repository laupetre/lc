# Terraform variables - Update these values for your deployment

# Required: Your OpenAI API key
openai_api_key = "your-openai-api-key-here"

# Required: GitHub repository information for OIDC authentication
github_org    = "your-github-username-or-org"
github_repo   = "langChain"
github_branch = "main"

# Optional: Override default values if needed
project               = "lc-swa"
location              = "eastus"
resource_group_name   = "lc-swa-rg"
acr_name              = "lcacrio"
openai_model          = "gpt-4o-mini"
containerapp_env_name = "lc-swa-env"
containerapp_name     = "lc-swa-api"
swa_name              = "lc-swa-frontend"
