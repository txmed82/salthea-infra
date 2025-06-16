# ------------------------------
# Azure Key Vault
# ------------------------------
resource "azurerm_key_vault" "salthea_kv" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.salthea_rg.location
  resource_group_name         = azurerm_resource_group.salthea_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"  # Temporarily allow all for easier development
    # ip_rules       = [] # Temporarily allow all for easier development
    virtual_network_subnet_ids = []
  }

  # Only include the current user access policy here
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "Purge"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update"
    ]
  }

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# ------------------------------
# Key Vault Access Policies (as separate resources to avoid cycles)
# ------------------------------
resource "azurerm_key_vault_access_policy" "app_access" {
  key_vault_id = azurerm_key_vault.salthea_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.salthea_api.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [
    azurerm_linux_web_app.salthea_api
  ]
}

resource "azurerm_key_vault_access_policy" "staging_app_access" {
  key_vault_id = azurerm_key_vault.salthea_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app_slot.staging_slot.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [
    azurerm_linux_web_app_slot.staging_slot
  ]
}

resource "azurerm_key_vault_access_policy" "frontend_app_access" {
  key_vault_id = azurerm_key_vault.salthea_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.salthea_frontend.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [
    azurerm_linux_web_app.salthea_frontend
  ]
}

resource "azurerm_key_vault_access_policy" "frontend_staging_app_access" {
  key_vault_id = azurerm_key_vault.salthea_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app_slot.frontend_staging_slot.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [
    azurerm_linux_web_app_slot.frontend_staging_slot
  ]
}

# ------------------------------
# Key Vault Secrets
# ------------------------------
# Clerk secrets
resource "azurerm_key_vault_secret" "clerk_secret" {
  name         = "ClerkSecretKey"
  value        = var.clerk_secret_key_value
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "clerk_pub" {
  name         = "ClerkPublishableKey"
  value        = var.clerk_publishable_key_value
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# Valyu API Key
resource "azurerm_key_vault_secret" "valyu_api_key" {
  name         = "ValyuApiKey"
  value        = var.valyu_api_key_value
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# OpenAI Deployment Name
resource "azurerm_key_vault_secret" "openai_deployment" {
  name         = "AzureOpenAIDeploymentName"
  value        = var.openai_deployment_name
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# OpenAI credentials
resource "azurerm_key_vault_secret" "openai_endpoint" {
  name         = "AzureOpenAIEndpoint"
  value        = azurerm_cognitive_account.salthea_openai.endpoint
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "AzureOpenAIKey"
  value        = azurerm_cognitive_account.salthea_openai.primary_access_key
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# Staging Cosmos DB Connection String (Placeholder - update with actual staging DB connection string or use production one)
resource "azurerm_key_vault_secret" "staging_cosmos_connection" {
  name         = var.staging_cosmos_db_connection_string_secret_name
  value        = "YOUR_STAGING_COSMOS_DB_CONNECTION_STRING_OR_USE_PROD" # Placeholder: Update this value!
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# ------------------------------
# New secrets for FHIR push + Particle webhook
# ------------------------------

resource "azurerm_key_vault_secret" "azure_fhir_url" {
  name         = "azure-fhir-url"
  value        = "https://${var.fhir_service_name}.azurehealthcareapis.com"
  key_vault_id = azurerm_key_vault.salthea_kv.id
  depends_on   = [azurerm_healthcare_fhir_service.salthea_fhir]
}

resource "azurerm_key_vault_secret" "azure_tenant_id" {
  name         = "azure-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "azure_client_id" {
  name         = "azure-client-id"
  value        = azuread_application.fhir_client.application_id
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "azure_client_secret" {
  name         = "azure-client-secret"
  value        = azuread_application_password.fhir_client_secret.value
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "particle_webhook_secret" {
  name         = "particle-webhook-secret"
  value        = var.particle_webhook_secret_value
  key_vault_id = azurerm_key_vault.salthea_kv.id
} 