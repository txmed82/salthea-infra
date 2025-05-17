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

# ------------------------------
# Monitoring Action Group
# ------------------------------
resource "azurerm_monitor_action_group" "email_alert_ag" {
  name                = "salthea-email-actiongroup"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  short_name          = "SaltheaAlrt"

  email_receiver {
    name          = "sendToAdmin"
    email_address = var.alert_notification_email
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# ------------------------------
# Monitoring Alert Rules
# ------------------------------

# Alert for High Average Server Response Time (Latency)
resource "azurerm_monitor_metric_alert" "high_latency_alert" {
  name                = "salthea-high-avg-latency-alert"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  scopes              = [azurerm_application_insights.salthea_insights.id]
  description         = "Action will be triggered when average server response time is high."
  enabled             = true
  frequency           = "PT5M"  # Evaluate every 5 minutes
  window_size         = "PT15M" # Over the last 15 minutes
  severity            = 2 # Warning

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "requests/duration" # Average server response time
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2000 # Milliseconds (e.g., 2 seconds)
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert_ag.id
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Alert for High Server Failure Rate (5xx errors)
resource "azurerm_monitor_metric_alert" "high_5xx_alert" {
  name                = "salthea-high-5xx-failure-alert"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  scopes              = [azurerm_application_insights.salthea_insights.id]
  description         = "Action will be triggered when the count of server-side failures (5xx) is high."
  enabled             = true
  frequency           = "PT5M"  # Evaluate every 5 minutes
  window_size         = "PT15M" # Over the last 15 minutes
  severity            = 1 # Critical

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "requests/failed" # Count of failed requests
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 5 # e.g., more than 5 failed requests in the window
    # To filter specifically for 5xx errors, you might need to add a dimension or use a log alert for more precision.
    # This basic alert triggers on any failed request reported by App Insights.
    # Dimension for result code (example, may need adjustment based on actual dimension names):
    # dimension {
    #   name     = "request/resultCode"
    #   operator = "StartsWith" # Or "Equals" if you list all 5xx codes
    #   values   = ["5"]
    # }
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alert_ag.id
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
} 