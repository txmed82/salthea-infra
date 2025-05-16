# ------------------------------
# Azure Blob Storage
# ------------------------------
resource "azurerm_storage_account" "salthea_storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.salthea_rg.name
  location                 = azurerm_resource_group.salthea_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    # Consider adding delete_retention_policy for recovery
  }

  # Configure network rules to deny public access by default
  public_network_access_enabled = true    # TEMPORARILY SET TO TRUE
  network_rules {
    default_action             = "Allow"  # Temporarily allow all for easier development
    bypass                     = ["AzureServices"] 
    # ip_rules                   = [] # Temporarily allow all for easier development
    virtual_network_subnet_ids = [] 
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

resource "azurerm_storage_container" "salthea_uploads" {
  name                  = "salthea-uploads"
  storage_account_name  = azurerm_storage_account.salthea_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "medical_records" {
  name                  = "medical-records"
  storage_account_name  = azurerm_storage_account.salthea_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "wearable_data" {
  name                  = "wearable-data"
  storage_account_name  = azurerm_storage_account.salthea_storage.name
  container_access_type = "private"
}

# Store Storage Account Connection String in Key Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "StorageConnectionString"
  value        = azurerm_storage_account.salthea_storage.primary_connection_string
  key_vault_id = azurerm_key_vault.salthea_kv.id
} 