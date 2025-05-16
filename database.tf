# ------------------------------
# Cosmos DB (MongoDB API)
# ------------------------------
resource "azurerm_cosmosdb_account" "salthea_cosmos" {
  name                = var.cosmos_account_name
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.salthea_rg.location
    failover_priority = 0
  }

  # Enable automatic failover
  enable_automatic_failover = true

  # Use virtual network filtering
  is_virtual_network_filter_enabled = true
  virtual_network_rule {
    id = azurerm_subnet.backend_subnet.id
  }

  # Set default identity
  identity {
    type = "SystemAssigned"
  }

  # Enable private network access only
  public_network_access_enabled = true

  # Disable IP rules as access is now via private endpoint
  ip_range_filter = "130.45.49.7"

  # For development, you might allow all IPs if needed, but be cautious:
  # ip_range_filter = "0.0.0.0/0"

  # Consider if network_acl_bypass_for_azure_services is needed if other Azure services need to connect
  # network_acl_bypass_for_azure_services = true

  # Add this tag for HIPAA compliance tracking
  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}

# Create Cosmos DB Databases
resource "azurerm_cosmosdb_mongo_database" "salthea_db" {
  name                = var.cosmos_db_name
  resource_group_name = azurerm_resource_group.salthea_rg.name
  account_name        = azurerm_cosmosdb_account.salthea_cosmos.name
  throughput          = var.cosmos_throughput
}

# Create Collections for Users and Messages
resource "azurerm_cosmosdb_mongo_collection" "users_collection" {
  name                = "users"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  account_name        = azurerm_cosmosdb_account.salthea_cosmos.name
  database_name       = azurerm_cosmosdb_mongo_database.salthea_db.name

  # Set index for user ID
  index {
    keys   = ["_id"]
    unique = true
  }

  # Set index for Clerk user ID
  index {
    keys   = ["clerkUserId"]
    unique = true
  }
}

resource "azurerm_cosmosdb_mongo_collection" "messages_collection" {
  name                = "messages"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  account_name        = azurerm_cosmosdb_account.salthea_cosmos.name
  database_name       = azurerm_cosmosdb_mongo_database.salthea_db.name

  # Set index for message ID
  index {
    keys   = ["_id"]
    unique = true
  }

  # Set index for user ID to query messages by user
  index {
    keys = ["userId"]
  }

  # Set index for timestamp for sorting
  index {
    keys = ["timestamp"]
  }
}

# Store Cosmos DB Connection String in Key Vault for secure access
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = "CosmosDbConnectionString"
  value        = azurerm_cosmosdb_account.salthea_cosmos.connection_strings[0]
  key_vault_id = azurerm_key_vault.salthea_kv.id
} 