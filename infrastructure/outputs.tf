output "azure_container_registry_fqdn" {
  value = azurerm_container_registry.acr.login_server
  description = "The login server for Azure Container Registry"
}

output "azure_container_registry_username" {
  value = azurerm_container_registry.acr.admin_username
  description = "The (admin) username for Azure Container Registry"
}

output "azure_container_registry_password" {
  value = azurerm_container_registry.acr.admin_password
  description = "The (admin) password for Azure Container Registry"
  sensitive = true
}

output "azurerm_kubernetes_cluster_version" {
  value = azurerm_kubernetes_cluster.aks.kubernetes_version
  description = "The Kubernetes version"
}

output "ssh_info" {
  value = "ssh ${var.ssh_username}@${azurerm_linux_virtual_machine.jump-server-vm.public_ip_address} -i ${var.ssh_private_key_path} -o StrictHostKeyChecking=no"
  description = "The ssh information for the jump server"
}
