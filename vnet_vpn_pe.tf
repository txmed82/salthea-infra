// Terraform stubs for CLI-created networking objects
// These resources already exist in Azure.  We import them once and
// then let Terraform keep them.  We ignore all attributes so future
// applies never try to modify or destroy them.

// Add data sources at top

data "azurerm_virtual_network" "salthea_vnet" {
  name                = "salthea-vnet"
  resource_group_name = azurerm_resource_group.salthea_rg.name
}

data "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = data.azurerm_virtual_network.salthea_vnet.name
  resource_group_name  = azurerm_resource_group.salthea_rg.name
}

data "azurerm_subnet" "priv_endpoints" {
  name                 = "priv-endpoints"
  virtual_network_name = data.azurerm_virtual_network.salthea_vnet.name
  resource_group_name  = azurerm_resource_group.salthea_rg.name
}

resource "azurerm_public_ip" "salthea_vpn_pip" {
  name                = "salthea-vpn-pip"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  location            = azurerm_resource_group.salthea_rg.location
  allocation_method   = "Static"

  lifecycle {
    ignore_changes = all
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network_gateway" "salthea_vpn" {
  name                = "salthea-vpn"
  location            = azurerm_resource_group.salthea_rg.location
  resource_group_name = azurerm_resource_group.salthea_rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.salthea_vpn_pip.id
    subnet_id                     = data.azurerm_subnet.gateway_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  // The existing gateway has OpenVPN with AAD — we ignore details to avoid drift
  lifecycle {
    ignore_changes = all
    prevent_destroy = true
  }
}

// Cosmos Private Endpoint and its NIC live in subnet "priv-endpoints"
resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = "salthea-cosmos-pe"
  resource_group_name = azurerm_resource_group.salthea_rg.name
  location            = azurerm_resource_group.salthea_rg.location
  subnet_id           = data.azurerm_subnet.priv_endpoints.id

  private_service_connection {
    name                           = "salthea-cosmos-pe-conn"
    private_connection_resource_id = azurerm_cosmosdb_account.salthea_cosmos.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  lifecycle {
    ignore_changes = all
    prevent_destroy = true
  }
}

// Private DNS zones (mongo + documents) + VNet links
resource "azurerm_private_dns_zone" "mongo" {
  name                = "mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.salthea_rg.name

  lifecycle {
    ignore_changes   = all
    prevent_destroy = true
  }
}
resource "azurerm_private_dns_zone" "mongo_privatelink" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.salthea_rg.name

  lifecycle {
    ignore_changes   = all
    prevent_destroy = true
  }
}
resource "azurerm_private_dns_zone" "documents_privatelink" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.salthea_rg.name

  lifecycle {
    ignore_changes   = all
    prevent_destroy = true
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "mongo_link" {
  name                  = "salthea-vnet-mongo-public"
  resource_group_name   = azurerm_resource_group.salthea_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mongo.name
  virtual_network_id    = data.azurerm_virtual_network.salthea_vnet.id

  lifecycle {
    ignore_changes   = all
    prevent_destroy = true
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "documents_link" {
  name                  = "salthea-vnet-link"
  resource_group_name   = azurerm_resource_group.salthea_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.documents_privatelink.name
  virtual_network_id    = data.azurerm_virtual_network.salthea_vnet.id

  lifecycle {
    ignore_changes   = all
    prevent_destroy = true
  }
}

// Ensure Cosmos account keeps public traffic disabled & no IP rules
// (Removed duplicate stub; use existing resource in database.tf and adjust lifecycle there if needed) 