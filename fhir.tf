# ------------------------------
# Azure API for FHIR Service
# ------------------------------

# Azure Healthcare APIs Workspace
resource "azurerm_healthcare_workspace" "salthea_healthcare_workspace" {
  name                = "saltheahealthcarews"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  location            = "southcentralus"
  
  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# Azure FHIR Service
resource "azurerm_healthcare_fhir_service" "salthea_fhir" {
  name                = var.fhir_service_name
  resource_group_name = azurerm_resource_group.salthea_rg.name
  location            = "southcentralus"
  workspace_id        = azurerm_healthcare_workspace.salthea_healthcare_workspace.id
  kind                = var.fhir_service_kind

  authentication {
    authority                = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    audience                 = "https://${var.fhir_service_name}.azurehealthcareapis.com"
    smart_proxy_enabled      = true
    # Note: allowed_audiences might not be supported in all provider versions
    # We'll configure it through a separate resource if needed
  }

  identity {
    type = "SystemAssigned"
  }

  configuration_export_storage_account_name = azurerm_storage_account.salthea_storage.name

  cors {
    allowed_origins     = var.cors_allowed_origins
    allowed_headers     = ["*"]
    allowed_methods     = ["GET", "POST", "PUT", "DELETE", "PATCH"]
    max_age_in_seconds  = 3600
  }

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# Private Endpoint for FHIR Service - COMMENTED OUT UNTIL SUBNET IS CREATED
# resource "azurerm_private_endpoint" "fhir_private_endpoint" {
#   name                = "${var.fhir_service_name}-pe"
#   location            = azurerm_resource_group.salthea_rg.location
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#   subnet_id           = azurerm_subnet.private_endpoints_subnet.id
#
#   private_service_connection {
#     name                           = "${var.fhir_service_name}-privateserviceconnection"
#     private_connection_resource_id = azurerm_healthcare_fhir_service.salthea_fhir.id
#     is_manual_connection           = false
#     subresource_names              = ["fhir"]
#   }
#
#   tags = {
#     environment = var.environment
#     project     = var.project_name
#     hipaa       = var.hipaa_compliant ? "true" : "false"
#   }
# }

# Create Private DNS Zone for FHIR service
resource "azurerm_private_dns_zone" "fhir_dns_zone" {
  name                = "privatelink.azurehealthcareapis.com"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  
  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Private DNS link to VNet - DISABLED due to VNet removal
# resource "azurerm_private_dns_zone_virtual_network_link" "fhir_dns_link" {
#   name                  = "fhir-dns-link"
#   resource_group_name   = azurerm_resource_group.salthea_rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.fhir_dns_zone.name
#   virtual_network_id    = azurerm_virtual_network.salthea_vnet.id
#   registration_enabled  = false
#   
#   tags = {
#     environment = var.environment
#     project     = var.project_name
#   }
# }

# Create a DNS record for the private endpoint - COMMENTED OUT UNTIL PRIVATE ENDPOINT IS CREATED
# resource "azurerm_private_dns_a_record" "fhir_dns_record" {
#   name                = var.fhir_service_name
#   zone_name           = azurerm_private_dns_zone.fhir_dns_zone.name
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.fhir_private_endpoint.private_service_connection[0].private_ip_address]
# }

# Add diagnostic settings for FHIR service
resource "azurerm_monitor_diagnostic_setting" "fhir_diag" {
  name                       = "${var.fhir_service_name}-diag"
  target_resource_id         = azurerm_healthcare_fhir_service.salthea_fhir.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.salthea_logs.id

  enabled_log {
    category = "AuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Store FHIR Service credentials in Key Vault
resource "azurerm_key_vault_secret" "fhir_service_url" {
  name         = "FHIRServiceURLV2"
  value        = "https://${var.fhir_service_name}.azurehealthcareapis.com"
  key_vault_id = azurerm_key_vault.salthea_kv.id
  depends_on = [
    azurerm_healthcare_fhir_service.salthea_fhir
  ]
}

# Output FHIR Service URL
output "fhir_service_url" {
  value       = "https://${var.fhir_service_name}.azurehealthcareapis.com"
  description = "The URL of the FHIR service"
  sensitive   = false
}

# Add RBAC role assignment for App Service to access FHIR
resource "azurerm_role_assignment" "app_service_fhir_contributor" {
  scope                = azurerm_healthcare_fhir_service.salthea_fhir.id
  role_definition_name = "FHIR Data Contributor"
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  
  depends_on = [
    azurerm_healthcare_fhir_service.salthea_fhir,
    azurerm_linux_web_app.salthea_api
  ]
}

# Add RBAC role assignment for Staging Slot to access FHIR
resource "azurerm_role_assignment" "staging_fhir_contributor" {
  scope                = azurerm_healthcare_fhir_service.salthea_fhir.id
  role_definition_name = "FHIR Data Contributor"
  principal_id         = azurerm_linux_web_app_slot.staging_slot.identity[0].principal_id
  
  depends_on = [
    azurerm_healthcare_fhir_service.salthea_fhir,
    azurerm_linux_web_app_slot.staging_slot
  ]
}

# Add FHIR Data Reader role to allow read-only access from read-only contexts
resource "azurerm_role_assignment" "app_service_fhir_reader" {
  scope                = azurerm_healthcare_fhir_service.salthea_fhir.id
  role_definition_name = "FHIR Data Reader"
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  
  depends_on = [
    azurerm_healthcare_fhir_service.salthea_fhir,
    azurerm_linux_web_app.salthea_api
  ]
}

# Add FHIR Data Exporter role to allow data export operations
resource "azurerm_role_assignment" "app_service_fhir_exporter" {
  scope                = azurerm_healthcare_fhir_service.salthea_fhir.id
  role_definition_name = "FHIR Data Exporter"
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
  
  depends_on = [
    azurerm_healthcare_fhir_service.salthea_fhir,
    azurerm_linux_web_app.salthea_api
  ]
}

# Create Recovery Services Vault for backup
resource "azurerm_recovery_services_vault" "salthea_vault" {
  name                = "salthea-recovery-vault"
  location            = "southcentralus"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  sku                 = "Standard"
  
  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# Add backup policy for FHIR service data
resource "azurerm_backup_policy_vm" "fhir_backup_policy" {
  name                = "fhir-backup-policy"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.salthea_vault.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = 1
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
} 