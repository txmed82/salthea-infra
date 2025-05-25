# ------------------------------
# Virtual Network for Improved Security - TEMPORARILY DISABLED
# This networking infrastructure is causing CosmosDB connectivity issues
# ------------------------------
# resource "azurerm_virtual_network" "salthea_vnet" {
#   name                = var.vnet_name
#   address_space       = var.vnet_address_space
#   location            = azurerm_resource_group.salthea_rg.location
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#
#   tags = {
#     environment = var.environment
#     project     = var.project_name
#   }
# }

# resource "azurerm_subnet" "backend_subnet" {
#   name                 = var.backend_subnet_name
#   resource_group_name  = azurerm_resource_group.salthea_rg.name
#   virtual_network_name = azurerm_virtual_network.salthea_vnet.name
#   address_prefixes     = [var.backend_subnet_address_prefix]
#   service_endpoints    = ["Microsoft.KeyVault", "Microsoft.AzureCosmosDB", "Microsoft.Storage"]
#
#   delegation {
#     name = "delegation"
#
#     service_delegation {
#       name    = "Microsoft.Web/serverFarms"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
#     }
#   }
# }

# resource "azurerm_subnet" "private_endpoints_subnet" {
#   name                 = "private-endpoints-subnet"
#   resource_group_name  = azurerm_resource_group.salthea_rg.name
#   virtual_network_name = azurerm_virtual_network.salthea_vnet.name
#   address_prefixes     = [var.private_endpoints_subnet_address_prefix]
# }

# resource "azurerm_network_security_group" "backend_nsg" {
#   name                = "${var.backend_subnet_name}-nsg"
#   location            = azurerm_resource_group.salthea_rg.location
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#
#   tags = {
#     environment = var.environment
#     project     = var.project_name
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "backend_nsg_association" {
#   subnet_id                 = azurerm_subnet.backend_subnet.id
#   network_security_group_id = azurerm_network_security_group.backend_nsg.id
# }

# ------------------------------
# App Service Virtual Network Integration - TEMPORARILY DISABLED
# This was causing Azure OpenAI SDK connectivity issues
# ------------------------------
# resource "azurerm_app_service_virtual_network_swift_connection" "app_vnet_integration" {
#   app_service_id = azurerm_linux_web_app.salthea_api.id
#   subnet_id      = azurerm_subnet.backend_subnet.id
# }

# ------------------------------
# Private Endpoints for Enhanced Security - TEMPORARILY DISABLED
# ------------------------------
# resource "azurerm_private_endpoint" "cosmos_private_endpoint" {
#   name                = "cosmos-private-endpoint"
#   location            = azurerm_resource_group.salthea_rg.location
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#   subnet_id           = azurerm_subnet.private_endpoints_subnet.id
#
#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_db.id]
#   }
#
#   private_service_connection {
#     name                           = "cosmos-private-connection"
#     is_manual_connection           = false
#     private_connection_resource_id = azurerm_cosmosdb_account.salthea_cosmos.id
#     subresource_names              = ["Sql"]
#   }
#   tags = var.tags
# }
#
# resource "azurerm_private_endpoint" "storage_private_endpoint" {
#   name                = "storage-private-endpoint"
#   location            = azurerm_resource_group.salthea_rg.location
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#   subnet_id           = azurerm_subnet.private_endpoints_subnet.id
#   
#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [azurerm_private_dns_zone.blob_storage.id]
#   }
#
#   private_service_connection {
#     name                           = "storage-private-connection"
#     is_manual_connection           = false
#     private_connection_resource_id = azurerm_storage_account.salthea_storage.id
#     subresource_names              = ["blob"]
#   }
#   tags = var.tags
# }
#
# resource "azurerm_private_endpoint" "keyvault_private_endpoint" {
#   name                = "keyvault-private-endpoint"
#   location            = azurerm_resource_group.salthea_rg.location
#   resource_group_name = azurerm_resource_group.salthea_rg.name
#   subnet_id           = azurerm_subnet.private_endpoints_subnet.id
#
#   private_dns_zone_group {
#     name                 = "default"
#     private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
#   }
#
#   private_service_connection {
#     name                           = "keyvault-private-connection"
#     is_manual_connection           = false
#     private_connection_resource_id = azurerm_key_vault.salthea_kv.id
#     subresource_names              = ["vault"]
#   }
#   tags = var.tags
# } 