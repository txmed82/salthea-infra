# ------------------------------
# SMART on FHIR Authentication
# ------------------------------

# Get tenant ID from current client configuration
data "azuread_client_config" "current" {}

# Azure AD Application Registration for SMART on FHIR
resource "azuread_application" "smart_on_fhir_app" {
  display_name     = "salthea-smart-on-fhir"
  sign_in_audience = "AzureADMyOrg"

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access FHIR resources on behalf of the signed-in user."
      admin_consent_display_name = "Access FHIR Resources"
      enabled                    = true
      id                         = "00000000-0000-0000-0000-000000000001" # This should be a UUID
      type                       = "User"
      user_consent_description   = "Allow the application to access FHIR resources on your behalf."
      user_consent_display_name  = "Access FHIR Resources"
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  web {
    redirect_uris = [
      "https://${var.app_service_name}.azurewebsites.net/auth/callback",
      "https://localhost:3000/auth/callback"
    ]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

# Service Principal for the Application Registration
resource "azuread_service_principal" "smart_on_fhir_sp" {
  client_id                     = azuread_application.smart_on_fhir_app.client_id
  app_role_assignment_required = false
  
  depends_on = [
    azuread_application.smart_on_fhir_app
  ]
}

# Client Secret for the Application Registration
resource "azuread_application_password" "smart_on_fhir_secret" {
  application_object_id = azuread_application.smart_on_fhir_app.object_id
  display_name          = "SMART on FHIR Client Secret"
  end_date              = "2099-12-31T23:59:59Z" # Should be rotated regularly in production
  
  depends_on = [
    azuread_application.smart_on_fhir_app
  ]
}

# Store SMART on FHIR credentials in Key Vault
resource "azurerm_key_vault_secret" "smart_client_id" {
  name         = "SmartOnFhirClientId"
  value        = azuread_application.smart_on_fhir_app.client_id
  key_vault_id = azurerm_key_vault.salthea_kv.id
  
  depends_on = [
    azuread_application.smart_on_fhir_app,
    azurerm_key_vault.salthea_kv
  ]
}

resource "azurerm_key_vault_secret" "smart_client_secret" {
  name         = "SmartOnFhirClientSecretV2"
  value        = azuread_application_password.smart_on_fhir_secret.value
  key_vault_id = azurerm_key_vault.salthea_kv.id
  
  depends_on = [
    azuread_application_password.smart_on_fhir_secret,
    azurerm_key_vault.salthea_kv
  ]
}

# Store Particle Health credentials in Key Vault
resource "azurerm_key_vault_secret" "particle_health_client_id" {
  name         = "ParticleHealthClientId"
  value        = var.particle_health_client_id
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "particle_health_client_secret" {
  name         = "ParticleHealthClientSecret"
  value        = var.particle_health_client_secret
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# Store TryTerra credentials in Key Vault
resource "azurerm_key_vault_secret" "tryterra_dev_id" {
  name         = "TryTerraDevId"
  value        = var.tryterra_dev_id
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "tryterra_api_key" {
  name         = "TryTerraApiKey"
  value        = var.tryterra_api_key
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# Grant access to the FHIR data using role assignment
resource "azurerm_role_assignment" "smart_on_fhir_rbac" {
  scope                = azurerm_healthcare_fhir_service.salthea_fhir.id
  role_definition_name = "FHIR Data Contributor"
  principal_id         = azuread_service_principal.smart_on_fhir_sp.object_id
  
  depends_on = [
    azurerm_healthcare_fhir_service.salthea_fhir,
    azuread_service_principal.smart_on_fhir_sp
  ]
} 