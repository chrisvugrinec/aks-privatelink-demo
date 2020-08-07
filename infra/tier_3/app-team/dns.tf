data "azurerm_virtual_network" "demo" {
  name                = var.mgmt-vnet
  resource_group_name = var.mgmt-rg
}

resource "azurerm_private_dns_zone" "demo" {
  name                = var.dns-zone
  resource_group_name = var.rg-name
  depends_on          = [azurerm_resource_group.demo]
}

resource "azurerm_private_dns_zone_virtual_network_link" "demo" {
  name                  = "mgmt-link"
  resource_group_name   = var.rg-name
  private_dns_zone_name = azurerm_private_dns_zone.demo.name
  virtual_network_id    = data.azurerm_virtual_network.demo.id
  depends_on          = [azurerm_private_dns_zone.demo]
}

resource "azurerm_private_dns_a_record" "hello_demo" {
  name                = "hello"
  zone_name           = azurerm_private_dns_zone.demo.name
  resource_group_name = var.rg-name
  ttl                 = 300
  records             = ["15.1.2.100"]
  depends_on          = [azurerm_private_dns_zone_virtual_network_link.demo]
}  


resource "azurerm_private_dns_a_record" "poker_demo" {
  name                = "poker"
  zone_name           = azurerm_private_dns_zone.demo.name
  resource_group_name = var.rg-name
  ttl                 = 300
  records             = ["15.1.2.100"]
  depends_on          = [azurerm_private_dns_zone_virtual_network_link.demo]
}
