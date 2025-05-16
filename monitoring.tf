# ------------------------------
# App Insights & Log Analytics
# ------------------------------
resource "azurerm_log_analytics_workspace" "salthea_logs" {
  name                = var.log_analytics_name
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

resource "azurerm_application_insights" "salthea_insights" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  workspace_id        = azurerm_log_analytics_workspace.salthea_logs.id
  application_type    = "web"

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# Store App Insights Connection String in Key Vault
resource "azurerm_key_vault_secret" "appinsights_connection" {
  name         = "AppInsightsConnectionString"
  value        = azurerm_application_insights.salthea_insights.connection_string
  key_vault_id = azurerm_key_vault.salthea_kv.id
} 