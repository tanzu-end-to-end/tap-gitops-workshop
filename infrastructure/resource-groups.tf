resource "azurerm_resource_group" "tgw-resource-group" {
  name     = var.azure_tgw_resource_group_name
  location = var.azure_location
}
