# ------------------------------
# App Service Plan
# ------------------------------
resource "azurerm_service_plan" "salthea_plan" {
  name                = var.app_service_plan_name
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
  name         = "AcrUsername"
  value        = azurerm_container_registry.salthea_acr.admin_username
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "AcrPassword"
  value        = azurerm_container_registry.salthea_acr.admin_password
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# ------------------------------
# App Service
# ------------------------------
resource "azurerm_linux_web_app" "salthea_api" {
  name                = var.app_service_name
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  service_plan_id     = azurerm_service_plan.salthea_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      docker_image     = "${var.acr_name}.azurecr.io/salthea-backend"
      docker_image_tag = "latest"
    }

    container_registry_use_managed_identity = true

    health_check_path = "/health"
    always_on         = true

    # Add IP restrictions and CORS
    # ip_restriction {  // Temporarily commented out to resolve plan issue
    #   action                    = "Allow"
    #   name                      = "front-end-access"
    #   virtual_network_subnet_id = azurerm_subnet.backend_subnet.id
    #   priority                  = 100
    # }

    # Set up CORS
    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = true
    }
  }

  app_settings = {
    # Docker settings
    WEBSITES_PORT              = "3000"
    DOCKER_REGISTRY_SERVER_URL = "https://${var.acr_name}.azurecr.io"

    # Environment and application settings
    NODE_ENV    = var.environment
    ENVIRONMENT = var.environment

    # Security and authentication secrets
    CLERK_SECRET_KEY      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_secret.id})"
    CLERK_PUBLISHABLE_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_pub.id})"

    # Database connection
    COSMOS_DB_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmos_connection.id})"

    # Storage
    STORAGE_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection.id})"

    # OpenAI configuration
    AZURE_OPENAI_ENDPOINT   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_endpoint.id})"
    AZURE_OPENAI_KEY        = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key.id})"
    AZURE_OPENAI_DEPLOYMENT = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_deployment.id})"

    # External APIs
    VALYU_API_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.valyu_api_key.id})"

    # Monitoring and logging
    APPLICATIONINSIGHTS_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.appinsights_connection.id})"
    SENTRY_DSN                            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sentry_dsn.id})"

    # Enable Key Vault reference for secrets
    AZURE_KEY_VAULT_ENDPOINT = azurerm_key_vault.salthea_kv.vault_uri

    # Log level
    LOG_LEVEL = "info"
  }

  # Add sticky settings to prevent reset during deployments
  sticky_settings {
    app_setting_names = [
      "WEBSITES_PORT",
      "DOCKER_REGISTRY_SERVER_URL"
    ]
  }

  # Configure logs
  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }

    application_logs {
      file_system_level = "Information"
    }
  }

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# ------------------------------
# Staging Slot for Blue-Green Deployments
# ------------------------------
resource "azurerm_linux_web_app_slot" "staging_slot" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.salthea_api.id

  site_config {
    # Inherits application_stack from production by default if not specified,
    # but we can be explicit if we want to ensure it uses managed identity for ACR.
    # If you want staging to pull a *different* default image/tag than production before CI/CD updates it,
    # you would specify application_stack here.
    # For now, let's ensure managed identity is clearly intended for ACR pulls.
    container_registry_use_managed_identity = true

    application_stack {
      # This defines the *initial* image. CI/CD will update this.
      # It's good practice to point it to a known stable tag or the same as prod initially.
      docker_image     = "${var.acr_name}.azurecr.io/salthea-backend"
      docker_image_tag = "latest" # Or a specific stable tag
    }

    vnet_route_all_enabled = true # If your production app uses VNet integration
    ftps_state             = "FtpsOnly"
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    use_32_bit_worker      = false
    always_on              = false # Staging slots often don't need to be always_on to save cost
                                 # but can be true if needed for your testing/warmup strategy.
  }

  app_settings = {
    "APP_ENV"                               = "staging"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~18" # Ensure this matches your application's Node.js major version
    "AZURE_COSMOSDB_CONNECTION_STRING"      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.staging_cosmos_connection.id})"
    "CLERK_SECRET_KEY"                      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_secret.id})"
    "CLERK_PUBLISHABLE_KEY"                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_pub.id})"
    "AZURE_OPENAI_ENDPOINT"                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_endpoint.id})"
    "AZURE_OPENAI_KEY"                      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key.id})"
    "AZURE_OPENAI_DEPLOYMENT_NAME"          = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_deployment.id})"
    "SENTRY_DSN"                            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sentry_dsn.id})"
    "VALYU_API_KEY"                         = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.valyu_api_key.id})"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.salthea_insights.connection_string
    // Add other staging-specific app settings if needed.
    // Note: To make settings "sticky" to the slot (not swap with production),
    // you currently need to configure that in Azure Portal post-creation or use different Key Vault secrets.
  }

  identity {
    type = "SystemAssigned"
  }

  virtual_network_subnet_id = azurerm_subnet.backend_subnet.id # Match production app service VNet integration

  tags = {
    environment = "staging"
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }

  depends_on = [
    azurerm_linux_web_app.salthea_api,
    azurerm_key_vault_secret.staging_cosmos_connection,
    azurerm_subnet.backend_subnet
  ]
}

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
# Role Assignments
# ------------------------------
# ACR Role Assignment
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.salthea_acr.id
}

# Storage Role Assignment
resource "azurerm_role_assignment" "storage_blob_contributor" {
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.salthea_storage.id
}

# ACR Role Assignment for Staging Slot
resource "azurerm_role_assignment" "staging_acr_pull" {
  principal_id         = azurerm_linux_web_app_slot.staging_slot.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.salthea_acr.id
} 