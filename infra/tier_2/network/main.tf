resource "azurerm_resource_group" "network-rg" {
  name     = var.mgmt-rg
  location = var.location
}

resource "azurerm_virtual_network" "mgmt-vnet" {
  name                = var.mgmt-vnet
  address_space       = [var.mgmt-vnet-cidr]
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  tags = var.tags
}

resource "azurerm_virtual_network" "aks-vnet" {
  name                = var.aks-vnet
  address_space       = [var.aks-vnet-cidr]
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  tags = var.tags
}

resource "azurerm_subnet" "mgmt-subnet" {
  name                 = var.mgmt-subnet
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.mgmt-vnet.name
  address_prefixes       = [var.mgmt-subnet-cidr]
}


data "azurerm_virtual_network" "mgmt-vnet" {
  name                = var.mgmt-vnet
  resource_group_name = azurerm_resource_group.network-rg.name
  depends_on          = [azurerm_virtual_network.mgmt-vnet]
}

data "azurerm_virtual_network" "aks-vnet" {
  name                = var.aks-vnet
  resource_group_name = azurerm_resource_group.network-rg.name
  depends_on          = [azurerm_virtual_network.aks-vnet]
}
