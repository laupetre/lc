# Azure AD OAuth Setup Guide

Quick reference guide for setting up OAuth authentication in your LangChain Chat Application.

## ⚡ Quick Setup Checklist

- [ ] Deploy infrastructure (Terraform workflow)
- [ ] Get Static Web App URL from Terraform outputs
- [ ] Create Azure AD App Registration
- [ ] Create Client Secret
- [ ] Configure Static Web App with credentials
- [ ] Test authentication

## 📋 Detailed Steps

### 1️⃣ Get Your Static Web App URL

After Terraform deployment, you'll see output like:
```
swa_default_hostname = "https://lc-swa-frontend.witty-stone-1234abc.eastus.azurestaticapps.net"
```

**Copy this URL** - you'll need it for the redirect URI.

### 2️⃣ Create App Registration in Azure AD

1. Go to [portal.azure.com](https://portal.azure.com)
2. Click **Azure Active Directory** (or search)
3. Click **App registrations** → **+ New registration**

**Configuration:**
- **Name**: `LangChain Chat App`
- **Account types**: Single tenant (your org only)
- **Redirect URI**: Select "Web" and enter:
  ```
  https://YOUR-APP.witty-stone-1234abc.eastus.azurestaticapps.net/.auth/login/aad/callback
  ```
  *(Replace with your actual SWA URL)*

4. Click **Register**
5. Copy the **Application (client) ID** - save it!

### 3️⃣ Create Client Secret

1. In your app, click **Certificates & secrets**
2. Click **+ New client secret**
3. Set:
   - Description: `Static Web App Auth`
   - Expires: `6 months` (or 12)
4. Click **Add**
5. **IMMEDIATELY copy the Value** - you can't see it again!

### 4️⃣ Configure Static Web App

1. Go to **Static Web Apps** in Azure Portal
2. Select your app (`lc-swa-frontend`)
3. Click **Configuration**
4. Click **+ Add** and add 2 settings:

**Setting 1:**
- **Name**: `MICROSOFT_CLIENT_ID`
- **Value**: Paste your Application (client) ID

**Setting 2:**
- **Name**: `MICROSOFT_CLIENT_SECRET`
- **Value**: Paste your secret value

5. Click **Save** ✨

### 5️⃣ Test It Out

1. Visit your Static Web App URL
2. Click **Login** button (top right)
3. Sign in with your Azure AD account
4. You should see your name in the header!

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| Redirect URI mismatch | Check the URI matches EXACTLY (no trailing slash) |
| Invalid client secret | Secret might have expired, create a new one |
| Can't sign in | Verify your Azure AD account has access to the tenant |
| 403/401 errors | Check application settings are saved in Static Web App |

### Common Error Codes

- **AADSTS50011**: Redirect URI doesn't match
- **AADSTS7000215**: Invalid client secret
- **AADSTS50126**: Invalid username or password

## 📝 Configuration Summary

**App Registration Settings:**
- Platform: Web
- Redirect URI: `https://YOUR-SWA/.auth/login/aad/callback`
- Account Type: Single tenant

**Static Web App Settings:**
- `MICROSOFT_CLIENT_ID`: Your app's client ID
- `MICROSOFT_CLIENT_SECRET`: Your client secret

**Frontend Configuration:**
- Handled by `staticwebapp.config.json`
- Login route: `/login`
- Logout route: `/logout`
- Auth endpoint: `/.auth/me`

## 🔒 Security Notes

- Client secrets expire - set calendar reminders
- Use HTTPS for all redirect URIs
- Single tenant is more secure than multi-tenant
- Never commit secrets to source control
- Rotate secrets periodically

## ✅ What You Should See

**Before Login:**
```
┌─────────────────────────────────────┐
│  🤖 LangChain Chat Assistant  [Login]│
└─────────────────────────────────────┘
```

**After Login:**
```
┌────────────────────────────────────────────┐
│  🤖 LangChain Chat Assistant  👤 Your Name [Logout]│
└────────────────────────────────────────────┘
```

## 🎯 Next Steps

1. Deploy your frontend code
2. Test the full authentication flow
3. Optionally restrict app access to specific users
4. Consider adding role-based access control

---

**Need Help?** Check the main [README.md](README.md) for more details.

