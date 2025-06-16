# ------------------------------
# Azure AI Search for mem0 Vector Store
# ------------------------------
resource "azurerm_search_service" "salthea_mem0_search" {
  name                = var.mem0_search_name
  resource_group_name = azurerm_resource_group.salthea_rg.name
  location            = azurerm_resource_group.salthea_rg.location
  sku                 = "standard"
  replica_count       = 1
  partition_count     = 1
  hosting_mode        = "default"

  semantic_search_sku = "standard"

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = true # TODO: flip to false after PE

  # CORS not supported in current provider version; configure manually if needed

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
    component   = "mem0-vector-store"
  }
}

# ------------------------------
# Azure OpenAI Embedding Model Deployment
# ------------------------------
resource "azurerm_cognitive_deployment" "mem0_embeddings_deployment" {
  name                 = var.mem0_embeddings_deployment_name
  cognitive_account_id = azurerm_cognitive_account.salthea_openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-large"
    version = "1"
  }

  scale {
    type     = "Standard"
    capacity = 20
  }

  depends_on = [
    azurerm_cognitive_account.salthea_openai
  ]
}

# ------------------------------
# Key Vault Secrets for mem0
# ------------------------------
resource "azurerm_key_vault_secret" "mem0_search_admin_key" {
  name         = "Mem0SearchAdminKey"
  value        = azurerm_search_service.salthea_mem0_search.primary_key
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "mem0_search_query_key" {
  name         = "Mem0SearchQueryKey"
  value        = azurerm_search_service.salthea_mem0_search.query_keys[0].key
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "mem0_search_endpoint" {
  name         = "Mem0SearchEndpoint"
  value        = "https://${azurerm_search_service.salthea_mem0_search.name}.search.windows.net"
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "mem0_search_name" {
  name         = "Mem0SearchName"
  value        = azurerm_search_service.salthea_mem0_search.name
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

resource "azurerm_key_vault_secret" "mem0_embeddings_deployment_name" {
  name         = "Mem0EmbeddingsDeploymentName"
  value        = azurerm_cognitive_deployment.mem0_embeddings_deployment.name
  key_vault_id = azurerm_key_vault.salthea_kv.id
}

# ------------------------------
# Role Assignments for mem0
# ------------------------------
# Grant backend App Service access to Search Service
resource "azurerm_role_assignment" "backend_search_contributor" {
  scope                = azurerm_search_service.salthea_mem0_search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_linux_web_app.salthea_api.identity[0].principal_id
}

# Grant staging slot access to Search Service
resource "azurerm_role_assignment" "staging_search_contributor" {
  scope                = azurerm_search_service.salthea_mem0_search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_linux_web_app_slot.staging_slot.identity[0].principal_id
}

# ------------------------------
# Application settings
# Current provider version lacks standalone app_settings resource.  
# Merge mem0-specific settings into the existing azurerm_linux_web_app
# blocks or enable once provider >=3.90 is available.
# ------------------------------

# ------------------------------
# Variables
# ------------------------------
variable "mem0_search_name" {
  description = "Name of the Azure AI Search service for mem0 vector store"
  type        = string
  default     = "salthea-mem0-search"
}

variable "mem0_embeddings_deployment_name" {
  description = "Name of the Azure OpenAI embeddings model deployment for mem0"
  type        = string
  default     = "text-embedding-3-large"
}

# ------------------------------
# Outputs
# ------------------------------
output "mem0_search_endpoint" {
  value       = "https://${azurerm_search_service.salthea_mem0_search.name}.search.windows.net"
  description = "The endpoint URL of the Azure AI Search service for mem0"
  sensitive   = false
}

output "mem0_search_name" {
  value       = azurerm_search_service.salthea_mem0_search.name
  description = "The name of the Azure AI Search service for mem0"
  sensitive   = false
}

output "mem0_embeddings_deployment_name" {
  value       = azurerm_cognitive_deployment.mem0_embeddings_deployment.name
  description = "The name of the Azure OpenAI embeddings model deployment for mem0"
  sensitive   = false
}
