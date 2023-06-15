resource "random_string" "random" {
  length  = 5
  special = false
  numeric = false
  upper = false
  lower = true
}

resource "azurerm_container_registry" "acr" {
  name                = "tapgitops${random_string.random.id}"
  location            = azurerm_resource_group.tgw-resource-group.location
  resource_group_name = azurerm_resource_group.tgw-resource-group.name
  sku                 = "Premium"
  admin_enabled       = true
}
