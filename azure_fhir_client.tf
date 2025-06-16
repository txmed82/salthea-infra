resource "azuread_application" "fhir_client" {
  display_name = "salthea-fhir-client"
}

resource "azuread_service_principal" "fhir_client_sp" {
  application_id = azuread_application.fhir_client.application_id
}

resource "azuread_application_password" "fhir_client_secret" {
  application_object_id = azuread_application.fhir_client.object_id
  display_name          = "salthea-fhir-secret"
  end_date_relative     = "8760h" # 1 year
}

# RBAC grant to FHIR service
resource "azurerm_role_assignment" "fhir_sp_contributor" {
  scope                = azurerm_healthcare_fhir_service.salthea_fhir.id
  role_definition_name = "FHIR Data Contributor"
  principal_id         = azuread_service_principal.fhir_client_sp.id
} 