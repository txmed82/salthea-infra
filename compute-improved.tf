# Improved App Service Configuration for Better Container Management
# This addresses the "latest" tag issue and implements proper blue-green deployment

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
      # Use semantic versioning or commit-based tags instead of "latest"
      docker_image_tag = "prod-current"
    }

    container_registry_use_managed_identity = true
    health_check_path = "/health"
    always_on         = true

    # Improved CORS configuration
    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = true
    }
  }

  app_settings = {
    # Container and runtime settings
    WEBSITES_PORT              = "3000"
    DOCKER_REGISTRY_SERVER_URL = "https://${var.acr_name}.azurecr.io"
    
    # Deployment tracking
    DEPLOYMENT_TAG             = "prod-current"
    DEPLOYMENT_TIMESTAMP       = timestamp()
    
    # Environment settings
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

    # FHIR service configuration
    FHIR_SERVICE_URL = "https://${var.fhir_service_name}.azurehealthcareapis.com"
    TENANT_ID = data.azurerm_client_config.current.tenant_id
    SMART_CLIENT_ID = azurerm_key_vault_secret.smart_client_id.value
    
    # OneRecord and TryTerra API settings
    ONERECORD_CLIENT_ID = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.onerecord_client_id.id})"
    ONERECORD_CLIENT_SECRET = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.onerecord_client_secret.id})"
    ONERECORD_REDIRECT_URI = "https://${var.app_service_name}.azurewebsites.net/api/onerecord/callback"  # Production URL
    TRYTERRA_DEV_ID = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.tryterra_dev_id.id})"
    TRYTERRA_API_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.tryterra_api_key.id})"

    # Monitoring and logging
    APPLICATIONINSIGHTS_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.appinsights_connection.id})"
    AZURE_KEY_VAULT_ENDPOINT = azurerm_key_vault.salthea_kv.vault_uri

    # Logging configuration
    LOG_LEVEL = "info"
  }

  # Sticky settings prevent them from swapping with slots
  sticky_settings {
    app_setting_names = [
      "WEBSITES_PORT",
      "DOCKER_REGISTRY_SERVER_URL",
      "DEPLOYMENT_TAG",
      "ONERECORD_REDIRECT_URI"  # Keep production-specific URLs sticky
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

# Improved Staging Slot Configuration
resource "azurerm_linux_web_app_slot" "staging_slot" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.salthea_api.id

  site_config {
    container_registry_use_managed_identity = true

    application_stack {
      docker_image     = "${var.acr_name}.azurecr.io/salthea-backend"
      # Use a predictable initial tag for staging
      docker_image_tag = "staging-initial"
    }

    vnet_route_all_enabled = true
    ftps_state             = "FtpsOnly"
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    use_32_bit_worker      = false
    always_on              = true
  }

  app_settings = {
    # Container and runtime settings
    "WEBSITES_PORT"              = "3000"
    "DOCKER_REGISTRY_SERVER_URL" = "https://${var.acr_name}.azurecr.io"
    
    # Staging-specific settings
    "APP_ENV"                               = "staging"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~18"
    "DEPLOYMENT_TAG"                        = "staging"
    "DEPLOYMENT_TIMESTAMP"                  = timestamp()
    
    # Use staging-specific cosmos connection
    "COSMOS_DB_CONNECTION_STRING"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.staging_cosmos_connection.id})"
    "STORAGE_CONNECTION_STRING"             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection.id})"
    
    # Shared auth settings
    "CLERK_SECRET_KEY"                      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_secret.id})"
    "CLERK_PUBLISHABLE_KEY"                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.clerk_pub.id})"
    "AZURE_OPENAI_ENDPOINT"                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_endpoint.id})"
    "AZURE_OPENAI_KEY"                      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key.id})"
    "AZURE_OPENAI_DEPLOYMENT"               = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_deployment.id})"
    "VALYU_API_KEY"                         = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.valyu_api_key.id})"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.salthea_insights.connection_string
    
    # FHIR service configuration for staging
    "FHIR_SERVICE_URL" = "https://${var.fhir_service_name}.azurehealthcareapis.com"
    "TENANT_ID" = data.azurerm_client_config.current.tenant_id
    "SMART_CLIENT_ID" = azurerm_key_vault_secret.smart_client_id.value
    
    # Staging-specific redirect URLs
    "ONERECORD_CLIENT_ID" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.onerecord_client_id.id})"
    "ONERECORD_CLIENT_SECRET" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.onerecord_client_secret.id})"
    "ONERECORD_REDIRECT_URI" = "https://${var.app_service_name}-staging.azurewebsites.net/api/onerecord/callback"
    "TRYTERRA_DEV_ID" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.tryterra_dev_id.id})"
    "TRYTERRA_API_KEY" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.tryterra_api_key.id})"
    
    # Staging-specific CORS
    "CORS_ALLOWED_ORIGINS"       = "https://salthea-frontend-staging.azurewebsites.net,http://localhost:3000"
    
    # Enhanced logging for staging
    "LOG_LEVEL" = "debug"
  }

  identity {
    type = "SystemAssigned"
  }

  virtual_network_subnet_id = azurerm_subnet.backend_subnet.id

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

# Create initial container images to avoid deployment issues
resource "null_resource" "initial_container_setup" {
  # This ensures we have the required tags in ACR
  provisioner "local-exec" {
    command = <<-EOT
      # Check if Azure CLI is available
      if ! command -v az &> /dev/null; then
        echo "Azure CLI not found. Please install and configure Azure CLI."
        exit 0
      fi
      
      # Check if we're logged in
      if ! az account show &> /dev/null; then
        echo "Not logged in to Azure CLI. Skipping container setup."
        exit 0
      fi
      
      # Try to create placeholder tags if they don't exist
      ACR_NAME="${var.acr_name}"
      
      # Import a minimal image as placeholder (using hello-world from Docker Hub)
      az acr import --name $ACR_NAME --source docker.io/library/hello-world:latest --image salthea-backend:prod-current --force || echo "Failed to create prod-current tag"
      az acr import --name $ACR_NAME --source docker.io/library/hello-world:latest --image salthea-backend:staging-initial --force || echo "Failed to create staging-initial tag"
    EOT
  }

  depends_on = [
    azurerm_container_registry.salthea_acr
  ]
}

# Output important information for deployment scripts
output "deployment_info" {
  description = "Information needed for deployment scripts"
  value = {
    acr_name = var.acr_name
    webapp_name = var.app_service_name
    resource_group = azurerm_resource_group.salthea_rg.name
    production_url = "https://${azurerm_linux_web_app.salthea_api.default_hostname}"
    staging_url = "https://${azurerm_linux_web_app_slot.staging_slot.default_hostname}"
  }
} 