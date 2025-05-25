output "app_service_url" {
  description = "URL of the deployed App Service"
  value       = "https://${azurerm_linux_web_app.salthea_api.default_hostname}"
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.salthea_cosmos.endpoint
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.salthea_insights.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.salthea_insights.connection_string
  sensitive   = true
}

output "azure_openai_endpoint" {
  description = "Azure OpenAI endpoint"
  value       = azurerm_cognitive_account.salthea_openai.endpoint
  sensitive   = true
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.salthea_kv.vault_uri
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.salthea_acr.login_server
}

output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.salthea_rg.name
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.salthea_storage.name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob storage endpoint"
  value       = azurerm_storage_account.salthea_storage.primary_blob_endpoint
}

# VNet outputs - DISABLED due to VNet removal
# output "backend_subnet_id" {
#   description = "ID of the backend subnet for VNet integration"
#   value       = azurerm_subnet.backend_subnet.id
# }

# output "vnet_id" {
#   description = "ID of the virtual network"
#   value       = azurerm_virtual_network.salthea_vnet.id
# }

output "app_service_staging_url" {
  description = "URL of the staging slot"
  value       = "https://${azurerm_linux_web_app_slot.staging_slot.default_hostname}"
}

output "app_service_default_hostname" {
  description = "The default hostname of the Salthea App Service"
  value       = azurerm_linux_web_app.salthea_api.default_hostname
}

output "staging_slot_default_hostname" {
  description = "The default hostname of the staging deployment slot."
  value       = azurerm_linux_web_app_slot.staging_slot.default_hostname
} 