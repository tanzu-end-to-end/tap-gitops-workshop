resource "azurerm_public_ip" "jump-server-pip" {
  name                = "jump-server-pip"
  location            = azurerm_resource_group.tgw-resource-group.location
  resource_group_name = azurerm_resource_group.tgw-resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
