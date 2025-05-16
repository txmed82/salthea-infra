# Create remote state infrastructure
resource "azurerm_resource_group" "tfstate_rg" {
  name     = "salthea-tfstate-rg"
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_storage_account" "tfstate_storage" {
  name                     = "saltheatfstate"
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = azurerm_resource_group.tfstate_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate_storage.name
  container_access_type = "private"
} 