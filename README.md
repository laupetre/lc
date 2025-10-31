# LangChain Chat Application

A full-stack chat application built with LangChain, FastAPI, and Azure services, deployed using GitHub Actions.

## Architecture

- **Frontend**: Static web app (HTML/CSS/JavaScript) deployed to Azure Static Web Apps
- **Backend**: FastAPI application with LangChain integration deployed to Azure Container Apps
- **Infrastructure**: Managed with Terraform, including Azure Container Registry, Container Apps, and Static Web Apps
- **CI/CD**: Automated deployment using GitHub Actions with OIDC authentication
- **Authentication**: Optional Azure AD OAuth via Static Web Apps (see [OAUTH_SETUP.md](OAUTH_SETUP.md))

## Prerequisites

1. **Azure Account**: Active Azure subscription
2. **GitHub Repository**: This code in a GitHub repository
3. **OpenAI API Key**: Valid OpenAI API key for LangChain integration
4. **Azure AD App Registration**: For OAuth authentication (optional)

## Setup Instructions

### 1. Configure Terraform Variables

Copy the example variables file and update it with your values:

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

Edit `infra/terraform.tfvars` and set:
- `openai_api_key`: Your OpenAI API key
- `github_org`: Your GitHub username or organization
- `github_repo`: Your repository name
- `github_branch`: Branch name (usually "main")

### 2. Set GitHub Repository Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions, and add these secrets:

**Required Secrets:**
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
- `AZURE_TENANT_ID`: Your Azure tenant ID
- `AZURE_CLIENT_ID`: Will be provided after first Terraform run
- `OPENAI_API_KEY`: Your OpenAI API key
- `SWA_DEPLOYMENT_TOKEN`: Static Web App deployment token (from Azure portal)

**Optional Variables:**
- `GITHUB_ORG`: Override GitHub organization (defaults to repository owner)
- `GITHUB_REPO`: Override repository name (defaults to current repo)
- `GITHUB_BRANCH`: Override branch name (defaults to current branch)

### 3. Deploy Infrastructure

1. **First-time setup**: Run the Terraform workflow manually:
   - Go to Actions tab in GitHub
   - Select "Terraform Infra" workflow
   - Click "Run workflow"

2. **Get deployment information**: After Terraform completes, check the workflow output for:
   - Azure Client ID (needed for `AZURE_CLIENT_ID` secret)
   - Static Web App deployment token (needed for `SWA_DEPLOYMENT_TOKEN` secret)

3. **Update secrets**: Add the missing secrets from step 2

### 4. Configure OAuth Authentication (Optional)

⚠️ **Important**: OAuth setup requires Azure AD application registration permissions. If your GitHub Actions service principal lacks these permissions, you'll need to create the app registration manually (see manual steps below).

Terraform will automatically create the Azure AD app registration for OAuth if you have the required permissions.

#### Automatic Setup (via Terraform)

After running the Terraform workflow, get your OAuth credentials from the workflow outputs:

1. **Get OAuth Credentials**:
   - In GitHub Actions workflow output, find:
     - `oauth_client_id`: Your Application (Client) ID
     - `oauth_client_secret`: Your client secret (sensitive)
     - `oauth_redirect_uri`: Already configured in app registration

2. **Configure Static Web App**:
   - In Azure Portal, go to **"Static Web Apps"**
   - Click on your Static Web App (e.g., `lc-swa-frontend`)
   - In the left menu, click **"Configuration"**
   - Click **"+ Add"** in the "Application settings" section
   - Add `MICROSOFT_CLIENT_ID` with the value from Terraform output
   - Click **"+ Add"** again and add `MICROSOFT_CLIENT_SECRET` with the secret value from Terraform output
   - Click **"Save"** button at the top

#### Manual Setup (if Terraform fails)

If Terraform doesn't have permissions to create app registrations, follow these manual steps:

**Step 1: Create Azure AD App Registration**

1. Go to [portal.azure.com](https://portal.azure.com) → Azure Active Directory → App registrations
2. Click **"+ New registration"**
3. Configure:
   - **Name**: `LangChain Chat App`
   - **Account types**: Single tenant
   - **Redirect URI**: `https://YOUR-SWA-URL/.auth/login/aad/callback`
4. Click **"Register"** and copy the **Application (Client) ID**

**Step 2: Create Client Secret**

1. In your app → Certificates & secrets
2. Click **"+ New client secret"**
3. Set expiration and description, click **"Add"**
4. **IMMEDIATELY copy the Value** (shown only once)

**Step 3: Configure Static Web App**

Add these settings in Static Web App → Configuration:
- `MICROSOFT_CLIENT_ID` = Your app's client ID
- `MICROSOFT_CLIENT_SECRET` = Your secret value

### 5. Test Authentication

1. **Visit Your Static Web App**:
   - Open your browser and navigate to your Static Web App URL
   - You should see the chat interface with a "Login" button in the top right

2. **Test Login**:
   - Click the **"Login"** button
   - You'll be redirected to Microsoft's login page
   - Sign in with your Azure AD account
   - You'll be redirected back to your app

3. **Verify Authentication**:
   - You should now see your name/email in the top right instead of "Login"
   - The "Login" button should be replaced with a "Logout" button
   - You can click "Logout" to sign out

#### Troubleshooting OAuth

If authentication doesn't work:

1. **Check Redirect URI**: Ensure it exactly matches:
   - `https://YOUR-SWA-URL/.auth/login/aad/callback` (no trailing slash)
   - Must be HTTPS

2. **Check Application Settings**: In Static Web App → Configuration, verify:
   - `MICROSOFT_CLIENT_ID` is set correctly
   - `MICROSOFT_CLIENT_SECRET` is set correctly
   - Both are saved (click "Save" if you see unsaved changes)

3. **Check App Registration**:
   - Go back to App registrations in Azure AD
   - Click on your app → Authentication
   - Verify the redirect URI is listed and correct

4. **Common Issues**:
   - **"AADSTS50011: The redirect URI...does not match"**: The redirect URI in the app registration doesn't exactly match the Static Web App URL
   - **"AADSTS7000215: Invalid client secret"**: The client secret expired or was copied incorrectly
   - **Can't sign in**: Make sure your Azure AD account has access to the tenant

### 6. Deploy Application

Once infrastructure is deployed and secrets are configured:

1. **API Deployment**: Push changes to the `api/` directory or run the "Deploy API" workflow manually
2. **Frontend Deployment**: Push changes to the `web/` directory or run the "Deploy Frontend" workflow manually

## Workflow Details

### Terraform Infrastructure (`terraform_infra.yml`)
- Deploys Azure resources (Resource Group, Container Registry, Container Apps, Static Web App)
- Sets up GitHub Actions OIDC authentication
- Creates federated identity credentials for secure Azure access

### API Deployment (`deploy_api.yml`)
- Builds Docker image from `api/Dockerfile`
- Pushes image to Azure Container Registry
- Updates Container App with new image
- Configures environment variables and secrets

### Frontend Deployment (`deploy_frontend.yml`)
- Generates `config.js` with API endpoint
- Deploys static files to Azure Static Web Apps
- Configures CORS settings

## Project Structure

```
├── api/                    # FastAPI backend
│   ├── app.py             # Main application
│   ├── Dockerfile         # Container definition
│   └── requirements.txt   # Python dependencies
├── web/                   # Frontend static files
│   ├── index.html         # Main HTML file
│   ├── style.css          # Styling
│   └── config.template.js # API endpoint template
├── infra/                 # Terraform infrastructure
│   ├── main.tf           # Resource definitions
│   ├── variables.tf      # Variable definitions
│   ├── outputs.tf       # Output values
│   └── terraform.tfvars.example # Example variables
├── .github/workflows/    # GitHub Actions
│   ├── terraform_infra.yml    # Infrastructure deployment
│   ├── deploy_api.yml         # API deployment
│   └── deploy_frontend.yml    # Frontend deployment
└── deploy.json           # Deployment configuration
```

## Local Development

### Backend
```bash
cd api
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### Frontend
```bash
cd web
# Edit config.template.js to point to local API
# Serve with any static file server
python -m http.server 8001
```

## Troubleshooting

### Common Issues

1. **Terraform fails**: Check that all required variables are set in `terraform.tfvars`
2. **API deployment fails**: Ensure Azure Container Registry exists and GitHub Actions has proper permissions
3. **Frontend deployment fails**: Verify Static Web App deployment token is correct
4. **CORS errors**: Check that `ALLOWED_ORIGIN` environment variable matches your Static Web App URL

### Getting Deployment Information

After successful Terraform deployment, check the workflow output or the generated `infra/deploy_info.txt` file for:
- Container App FQDN
- Static Web App hostname
- Required GitHub secrets

## Security Notes

- Uses GitHub Actions OIDC for secure Azure authentication (no service principal secrets)
- OpenAI API key is stored as a secret in Azure Container Apps
- CORS is configured to only allow requests from the Static Web App domain
- All sensitive values are properly marked as sensitive in Terraform
- Optional Azure AD OAuth authentication via Static Web Apps built-in auth

## Authentication

The application supports optional Azure AD OAuth authentication:

- **Frontend**: Uses Azure Static Web Apps built-in authentication
- **Configuration**: Managed via `staticwebapp.config.json`
- **User Experience**: Login/logout buttons with user info display
- **API**: Passes authentication context via headers (optional, will work without auth)

### OAuth Flow

```
User clicks "Login" 
    ↓
Redirect to Azure AD login page
    ↓
User authenticates with Azure AD
    ↓
Azure AD redirects back to app with token
    ↓
Static Web App validates token
    ↓
User is logged in (name displayed in UI)
```

**Note**: Authentication is entirely optional. If you don't configure OAuth, the app will work normally without requiring login.

## Contributing

1. Make changes to the appropriate directory (`api/` or `web/`)
2. Push to the main branch
3. GitHub Actions will automatically deploy the changes
4. For infrastructure changes, run the Terraform workflow manually
