# Azure Cognitive Language Service for CLU routing
resource "azurerm_cognitive_account" "language_service" {
  name                = var.language_service_name
  location            = "East US"  # Override to East US for CLU support
  resource_group_name = azurerm_resource_group.salthea_rg.name
  kind                = "TextAnalytics"
  sku_name            = var.language_service_sku

  public_network_access_enabled = true
  
  # Enable custom subdomain for CLU
  custom_subdomain_name = var.language_service_subdomain

  tags = {
    environment = var.environment
    project     = var.project_name
    service     = "language-understanding"
    purpose     = "intent-routing"
  }
}

# Output the Language Service endpoint and key for application configuration
output "language_service_endpoint" {
  value = azurerm_cognitive_account.language_service.endpoint
  description = "Azure Language Service endpoint URL"
}

output "language_service_key" {
  value = azurerm_cognitive_account.language_service.primary_access_key
  sensitive = true
  description = "Azure Language Service primary access key"
}

# Store Language Service credentials in Key Vault
resource "azurerm_key_vault_secret" "language_service_endpoint" {
  name         = "AzureLanguageEndpoint"
  value        = azurerm_cognitive_account.language_service.endpoint
  key_vault_id = azurerm_key_vault.salthea_kv.id

  tags = {
    environment = var.environment
    service     = "language-service"
  }
}

resource "azurerm_key_vault_secret" "language_service_key" {
  name         = "AzureLanguageKey"
  value        = azurerm_cognitive_account.language_service.primary_access_key
  key_vault_id = azurerm_key_vault.salthea_kv.id

  tags = {
    environment = var.environment
    service     = "language-service"
  }
}

# CLU Project name and deployment secrets for configuration
resource "azurerm_key_vault_secret" "clu_project_name" {
  name         = "AzureCluProjectName"
  value        = var.clu_project_name
  key_vault_id = azurerm_key_vault.salthea_kv.id

  tags = {
    environment = var.environment
    service     = "language-service"
  }
}

resource "azurerm_key_vault_secret" "clu_deployment_name" {
  name         = "AzureCluDeploymentName"
  value        = var.clu_deployment_name
  key_vault_id = azurerm_key_vault.salthea_kv.id

  tags = {
    environment = var.environment
    service     = "language-service"
  }
} 