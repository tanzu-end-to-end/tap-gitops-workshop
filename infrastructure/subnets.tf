resource "azurerm_subnet" "jump-server-subnet" {
  name                 = var.azure_jump_server_subnet_name
  resource_group_name  = azurerm_resource_group.tgw-resource-group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.azure_jump_server_subnet_cidr]
}

resource "azurerm_subnet_network_security_group_association" "jump-server-nsg-assoc" {
  subnet_id                 = azurerm_subnet.jump-server-subnet.id
  network_security_group_id = azurerm_network_security_group.jump-server-nsg.id
}
