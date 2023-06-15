#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

# Download GitOps reference implementation
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.5.1' --product-file-id=1467377
mkdir -p workshop-clusters
tar -xvf tanzu-gitops-ri-* -C workshop-clusters

# Download the workshop
rm -rf tap-gitops-workshop
git clone https://github.com/tanzu-end-to-end/tap-gitops-workshop.git

# Download and install Cluster Essentials
TAP_VERSION_YAML="/usr/local/bin/tap-gitops-workshop-scripts/tap-version.yaml"

CLUSTER_ESSENTIALS_VERSION=$(yq e .cluster_essentials.version $TAP_VERSION_YAML)

CLUSTER_ESSENTIALS_FILE="tanzu-cluster-essentials-linux-amd64-$CLUSTER_ESSENTIALS_VERSION.tgz"
CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=$(yq e .cluster_essentials.product_file_id $TAP_VERSION_YAML)

rm -rf generated/tanzu-cluster-essentials
mkdir -p generated/tanzu-cluster-essentials

if [[ ! -f "generated/$CLUSTER_ESSENTIALS_FILE" ]]; then
  pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version=$CLUSTER_ESSENTIALS_VERSION --product-file-id=$CLUSTER_ESSENTIALS_PRODUCT_FILE_ID --download-dir generated
fi

tar -xvf generated/$CLUSTER_ESSENTIALS_FILE -C generated/tanzu-cluster-essentials

(
  export INSTALL_BUNDLE=$(yq e .cluster_essentials.bundle $TAP_VERSION_YAML)
  export INSTALL_REGISTRY_HOSTNAME="registry.tanzu.vmware.com"
  export INSTALL_REGISTRY_USERNAME=$TANZU_REGISTRY_USERNAME
  export INSTALL_REGISTRY_PASSWORD=$TANZU_REGISTRY_PASSWORD

  cd generated/tanzu-cluster-essentials

  ./install.sh --yes
)

# Download and install Tanzu CLI
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

TAP_FILE='tanzu-framework-linux-amd64-*.tar'
TAP_FILE_PRODUCT_FILE_ID=$(yq e .tap.product_file_id $TAP_VERSION_YAML)
TANZU_CLI='tanzu-core-linux_amd64'

rm -f generated/$TAP_FILE
rm -rf generated/tanzu
mkdir -p generated/tanzu

pivnet download-product-files --product-slug='tanzu-application-platform' --release-version=$TAP_VERSION --product-file-id=$TAP_FILE_PRODUCT_FILE_ID --download-dir generated

tar -xvf generated/$TAP_FILE -C generated/tanzu

export TANZU_CLI_NO_INIT=true
sudo install generated/tanzu/cli/core/v*/$TANZU_CLI /usr/local/bin/tanzu

tanzu version

tanzu plugin install --local generated/tanzu/cli all

tanzu plugin list
