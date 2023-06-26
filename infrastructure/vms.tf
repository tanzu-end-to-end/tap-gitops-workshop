resource "azurerm_linux_virtual_machine" "jump-server-vm" {
  name                = "jump-server"
  location            = azurerm_resource_group.tgw-resource-group.location
  resource_group_name = azurerm_resource_group.tgw-resource-group.name
  size                = "Standard_D2s_v3"
  admin_username      = var.ssh_username

  custom_data = base64encode(templatefile("./cloud-init/cloud-config.yaml", {
    username                             = var.ssh_username
    gh_username                          = var.gh_username != null ? var.gh_token : ""
    gh_token                             = var.gh_token != null ? var.gh_token : ""
    tanzu_registry_username              = var.tanzu_registry_username
    tanzu_registry_password              = var.tanzu_registry_password
    tanzu_network_refresh_token          = var.tanzu_network_refresh_token
    ssh_public_key                       = file(var.ssh_public_key_path)
    git_auth_via_ssh_key                 = var.git_auth_via_ssh_key
    ssh_private_key                      = base64encode(file(var.ssh_private_key_path))
    ssh_private_key_passphrase_protected = var.ssh_private_key_passphrase_protected
    kubeconfig                           = base64encode(azurerm_kubernetes_cluster.aks.kube_config_raw)
    download_and_install                 = base64encode(file("./scripts/download-and-install.sh"))
    install_tools_script                 = base64encode(file("./scripts/install-tools.sh"))
    login_script                         = base64encode(file("./scripts/login.sh"))
    tap_version                          = base64encode(file("./scripts/tap-version.yaml"))
  }))

  network_interface_ids = [
    azurerm_network_interface.jump-server-nic.id,
  ]

  depends_on = [
    azurerm_subnet_network_security_group_association.jump-server-nsg-assoc,
    azurerm_kubernetes_cluster.aks
  ]

  admin_ssh_key {
    username   = var.ssh_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "null_resource" "cloud-init-wait" {
  triggers = {
    instance_id = azurerm_linux_virtual_machine.jump-server-vm.id
  }

  connection {
    type        = "ssh"
    user        = var.ssh_username
    private_key = var.ssh_private_key_passphrase_protected ? null : file(var.ssh_private_key_path)
    agent       = var.ssh_private_key_passphrase_protected
    host        = azurerm_linux_virtual_machine.jump-server-vm.public_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to finish'",
      "cloud-init status --wait > /dev/null",
      "echo 'cloud-init finished'",
      "cloud-init status",
    ]
  }

  depends_on = [
    azurerm_linux_virtual_machine.jump-server-vm
  ]
}
