# Tanzu GitOps Reference Implementation on Azure

In order to get started quickly, Azure infrastructure (e.g. Azure Kubernetes Service (AKS), Azure Container Registry (ACR) and a jumpbox) can be scaffolded via Terraform. The jumpbox contains all of the tools installed required for this workshop.

## Required CLIs, Plugins and Accounts

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://www.terraform.io/)
- [Tanzu Network account](https://network.tanzu.vmware.com/)
  - [Refresh token](https://network.tanzu.vmware.com/users/dashboard/edit-profile)
- SSH Key
- Git provider account (e.g. GitHub, Bitbucket)
  - GitHub personal access token (optional)

Additionally, you will need to accept any Tanzu Application Platform EULAs.

## Configuration

Utilizing Terraform conventions, make a copy `terraform.tfvars.example` and remove the `.example` extension. Edit this file and add values. Descriptions of the values below:

- `tanzu_network_refresh_token` (string) - The Tanzu network refresh token utilized to download software
- `ssh_private_key_path` (string) - The path to the private key.  
Used to SSH into the jumpbox.
    
  **NOTE:** For Azure, you must use an RSA SSH key, and it's recommended that your key indicate your desired SSH username (not email) or you may have validation issues with the Azure terraform module.  
  If you need to generate a new key, here's an example that will create a new keypair in your current directory:

  ```shell
  ssh-keygen -m PEM -t rsa -b 4096 -f "./azure-workshop-ssh" -C "$USER"
  ```
- `ssh_private_key_passphrase_protected` (bool) - On whether the SSH key has a passphrase (true) or not (false)
- `ssh_public_key_path` (string) - The path to the public SSH key. Used in the setup of the jumpbox.
- `ssh_username` (string) - The name used when SSH'ing into the jumpbox

- `gh_username` (string) - Username of the GitHub account.
- `gh_token` (string) - Value of the GitHub personal access token.
    
  **NOTE:** If you choose to use a GitHub Personal Access Token, the minimum required scopes for the `gh` CLI are `repo` (all) and `read:org`. You can add scopes for your tokens in the [GitHub Token Settings](https://github.com/settings/tokens/).

## Build Infrastructure

1. [Sign in with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
1. Run `terraform init`
1. Run `terraform plan`
1. Run `terraform apply -auto-approve`

## Infrastructure Information

During the installation of this workshop, some infrastructure information will be required. To obtain it, run the following commands to get AKS and ACR information.

```console
# SSH information, ACR and AKS info
terraform output
```

```console
# ACR admin password
terraform output azure_container_registry_password
```

### Jumpbox

The jumpbox contains a variety of tools as well as the kubeconfig for the AKS cluster. Installed tools:

- brew
- age
- Carvel
- direnv
- git
- gh (GitHub CLI)
- jq
- k9s
- kubectl
- Mozilla sops
- pivnet (Tanzu Network CLI)
- tree
- yq

After the tools are installed, automatic login into the Tanzu Network and GitHub will occur. Finally, the Tanzu CLI will be downloaded and installed as well as Cluster Essentials onto the AKS cluster.

## Cloud-init

During the setup of the jumpbox, [Cloud-init](https://cloudinit.readthedocs.io/) is utilized. Terraform will wait until this process is complete.

### Troubleshooting

If for some reason Cloud-init fails, SSH into the jump server. You can run some of the commands below to help troubleshoot the issue.

```console
# Get the status of Cloud-init
cloud-init status

# Check the Cloud-init log for errors in [cloud-config.yaml](./cloud-init/cloud-config.yaml)
sudo cat /var/log/cloud-init.log

# Check the Cloud-init output log for errors in the [scripts](./scripts/)
sudo cat /var/log/cloud-init-output.log

# Verify errors in the runcmd script
sudo vim /var/lib/cloud/instance/scripts/runcmd
```

Additionally, if you need to recreate the jumpbox, the Terraform command below will save some time by only recreating it:

```bash
terraform apply -auto-approve -replace="azurerm_linux_virtual_machine.jump-server-vm"
```