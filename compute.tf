# ------------------------------
# App Service Plan
# ------------------------------
resource "azurerm_service_plan" "salthea_plan" {
  name                = "salthea-app-plan"
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# ------------------------------
# Azure Container Registry
# ------------------------------
resource "azurerm_container_registry" "salthea_acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.salthea_rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  
  identity {
    type = "SystemAssigned"
  }

  # For Basic SKU, we need to remove network_rule_set
  # If you need network rules, upgrade to Premium SKU
  
  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Store ACR credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "ACRUsernameV2"
  value        = azurerm_container_registry.salthea_acr.admin_username
  key_vault_id = azurerm_key_vault.salthea_kv.id
  depends_on   = [azurerm_container_registry.salthea_acr]
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "ACRPasswordV2"
  value        = azurerm_container_registry.salthea_acr.admin_password
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# ------------------------------
# NOTE: Backend App Service resources moved to compute-improved.tf
# This file now only contains unique resources not in compute-improved.tf
# ------------------------------

# ------------------------------
# Azure OpenAI
# ------------------------------
resource "azurerm_cognitive_account" "salthea_openai" {
  name                = var.openai_name
  location            = "eastus" # Limited regions support OpenAI
  resource_group_name = azurerm_resource_group.salthea_rg.name
  kind                = "OpenAI"
  sku_name            = "S0"
  custom_subdomain_name = lower(var.openai_name)

  identity {
    type = "SystemAssigned"
  }

  # Removed network_acls block during development
  # When ready for production, add service endpoints and proper network rules

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# ------------------------------
# Azure OpenAI Model Deployment
# ------------------------------
resource "azurerm_cognitive_deployment" "gpt4o_deployment" {
  name                 = var.openai_deployment_name
  cognitive_account_id = azurerm_cognitive_account.salthea_openai.id
  
  model {
    format  = "OpenAI"
    name    = "gpt-4o"     # Confirm this exact model name in Azure portal for your region
    version = "2024-05-13" # Confirm available and desired version
  }
  
  scale {
    type     = "Standard"  # For Pay-As-You-Go model.
    capacity = 50          # Base capacity unit (e.g., 50 * 1000 = 50000 Tokens-Per-Minute).
                           # Actual billing for "Standard" type is based on consumption.
                           # For "Provisioned" type, this would represent reserved throughput units.
  }

  # version_upgrade_option was removed as it's not a valid argument in this context/version.
  # Default behavior or other settings in Azure portal might control version upgrades.

  # Tags are not directly supported on the deployment resource itself.
  # They are typically inherited from the parent cognitive account.

  depends_on = [
    azurerm_cognitive_account.salthea_openai
  ]
}

# ------------------------------
# Role Assignments
# ------------------------------
# ACR Role Assignment - reference to backend app in compute-improved.tf
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.salthea_acr.id
}

# Storage Role Assignment - reference to backend app in compute-improved.tf
resource "azurerm_role_assignment" "storage_blob_contributor" {
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.salthea_storage.id
}

# ACR Role Assignment for Staging Slot - reference to staging slot in compute-improved.tf
resource "azurerm_role_assignment" "staging_acr_pull" {
  principal_id         = azurerm_linux_web_app_slot.staging_slot.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.salthea_acr.id
}

# ------------------------------
# Frontend App Service
# ------------------------------
resource "azurerm_linux_web_app" "salthea_frontend" {
  name                = "salthea-frontend"
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  service_plan_id     = azurerm_service_plan.salthea_plan.id
  https_only          = true # Enforce HTTPS for the entire app service

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      node_version = "18-lts"
    }

    health_check_path = "/api/health"
    always_on         = true

    # Set up CORS if needed
    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = true
    }
  }

  app_settings = {
    # Environment and application settings
    NODE_ENV    = var.environment
    ENVIRONMENT = var.environment

    # Security and authentication secrets
    CLERK_SECRET_KEY      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_secret.id})"
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_pub.id})"
    
    # Backend API URL
    NEXT_PUBLIC_API_URL = "https://${var.app_service_name}.azurewebsites.net"

    # Monitoring
    APPLICATIONINSIGHTS_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.appinsights_connection.id})"

    # Enable Key Vault reference for secrets
    AZURE_KEY_VAULT_ENDPOINT = azurerm_key_vault.salthea_kv.vault_uri

    # Azure App Service Build Settings - Required for Oryx to build Next.js
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ENABLE_ORYX_BUILD = "true"
    BUILD_FLAGS = "UseExpressBuild"
    XDG_CACHE_HOME = "/tmp/.cache"
    
    # Force Azure to treat deployment as source code (not pre-built)
    WEBSITE_RUN_FROM_PACKAGE = "0"
    SCM_NO_REPOSITORY = "0"
    
    # Next.js specific build settings
    WEBSITE_NODE_DEFAULT_VERSION = "18.20.7"
    WEBSITE_NPM_DEFAULT_VERSION = "10.8.2"
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# ------------------------------
# Frontend Staging Slot for Blue-Green Deployments
# ------------------------------
resource "azurerm_linux_web_app_slot" "frontend_staging_slot" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.salthea_frontend.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      node_version = "18-lts"
    }

    health_check_path = "/api/health"
    always_on         = true
  }

  app_settings = {
    # Same app settings as the production slot
    NODE_ENV    = var.environment
    ENVIRONMENT = "staging"
    
    CLERK_SECRET_KEY      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_secret.id})"
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_pub.id})"
    
    # Frontend staging should point to the same backend as production, not to a non-existent staging backend
    NEXT_PUBLIC_API_URL = "https://${var.app_service_name}.azurewebsites.net"
    
    APPLICATIONINSIGHTS_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.appinsights_connection.id})"
    AZURE_KEY_VAULT_ENDPOINT = azurerm_key_vault.salthea_kv.vault_uri

    # Azure App Service Build Settings - Required for Oryx to build Next.js
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ENABLE_ORYX_BUILD = "true"
    BUILD_FLAGS = "UseExpressBuild"
    XDG_CACHE_HOME = "/tmp/.cache"
    
    # Force Azure to treat deployment as source code (not pre-built)
    WEBSITE_RUN_FROM_PACKAGE = "0"
    SCM_NO_REPOSITORY = "0"
    
    # Next.js specific build settings
    WEBSITE_NODE_DEFAULT_VERSION = "18.20.7"
    WEBSITE_NPM_DEFAULT_VERSION = "10.8.2"
  }

  tags = {
    environment = "staging"
    project     = var.project_name
  }
} 