resource "azurerm_network_interface" "jump-server-nic" {
  name                = "jump-server-nic"
  location            = azurerm_resource_group.tgw-resource-group.location
  resource_group_name = azurerm_resource_group.tgw-resource-group.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.jump-server-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump-server-pip.id
  }
}
