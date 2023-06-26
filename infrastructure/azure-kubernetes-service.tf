resource "azurerm_kubernetes_cluster" "aks" {
  name                = "tap-gitops"
  location            = azurerm_resource_group.tgw-resource-group.location
  resource_group_name = azurerm_resource_group.tgw-resource-group.name
  dns_prefix          = "tap-gitops"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}