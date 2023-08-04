variable "gh_username" {
  type = string
}

variable "gh_token" {
  type = string
}

variable "tanzu_registry_username" {
  type = string
}

variable "tanzu_registry_password" {
  type = string
}

variable "tanzu_network_refresh_token" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "ssh_private_key_passphrase_protected" {
  type = bool
}

variable "ssh_public_key_path" {
  type = string
}

variable "ssh_username" {
  type = string
}

# Azure

variable "azure_location" {
  type    = string
  default = "centralus"
}

variable "azure_tgw_resource_group_name" {
  type    = string
  default = "tap-gitops-workshop"
}

variable "azure_vnet_name" {
  type    = string
  default = "tap-gitops-workshop-vnet"
}

variable "azure_vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azure_jump_server_subnet_name" {
  type    = string
  default = "jump-server-subnet"
}

variable "azure_jump_server_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "azure_jump_server_nsg_name" {
  type    = string
  default = "jump-server-nsg"
}
