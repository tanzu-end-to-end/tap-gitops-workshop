#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

echo " === install-tanzu.sh === "

# pivnet
pivnet login --api-token="$TANZU_NETWORK_REFRESH_TOKEN"

# Download and install Cluster Essentials
TAP_VERSION_YAML="/usr/local/bin/tap-gitops-workshop-scripts/tap-version.yaml"

CLUSTER_ESSENTIALS_VERSION=$(yq e .cluster_essentials.version $TAP_VERSION_YAML)

CLUSTER_ESSENTIALS_PRODUCT_FILE="tanzu-cluster-essentials-linux-amd64-$CLUSTER_ESSENTIALS_VERSION.tgz"
CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=$(yq e .cluster_essentials.tanzu_net.linux_product_file_id $TAP_VERSION_YAML)

rm -f /tmp/$CLUSTER_ESSENTIALS_PRODUCT_FILE
rm -rf /tmp/tanzu-cluster-essentials
mkdir -p /tmp/tanzu-cluster-essentials

pivnet download-product-files \
  --product-slug='tanzu-cluster-essentials' \
  --release-version=$CLUSTER_ESSENTIALS_VERSION \
  --product-file-id=$CLUSTER_ESSENTIALS_PRODUCT_FILE_ID \
  --download-dir /tmp

tar -xvf /tmp/$CLUSTER_ESSENTIALS_PRODUCT_FILE -C /tmp/tanzu-cluster-essentials

(
  export INSTALL_BUNDLE=$(yq e .cluster_essentials.bundle $TAP_VERSION_YAML)
  export INSTALL_REGISTRY_HOSTNAME="registry.tanzu.vmware.com"
  export INSTALL_REGISTRY_USERNAME=$TANZU_REGISTRY_USERNAME
  export INSTALL_REGISTRY_PASSWORD=$TANZU_REGISTRY_PASSWORD

  cd /tmp/tanzu-cluster-essentials

  ./install.sh --yes
)

# Download and install Tanzu CLI
# NOTE: this is not done via a package manager since it creates a .config dir with restrictive permissions and can interfere with direnv
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

TANZU_CLI_PRODUCT_FILE='tanzu-cli-linux-amd64.tar.gz'
TANZU_CLI_PRODUCT_FILE_ID=$(yq e .tap.tanzu_cli.tanzu_net.linux_product_file_id $TAP_VERSION_YAML)
TANZU_CLI='tanzu-cli-linux_amd64'

rm -f /tmp/$TANZU_CLI_PRODUCT_FILE
rm -rf /tmp/tanzu
mkdir -p /tmp/tanzu

pivnet download-product-files \
  --product-slug='tanzu-application-platform' \
  --release-version=$TAP_VERSION \
  --product-file-id=$TANZU_CLI_PRODUCT_FILE_ID \
  --download-dir /tmp

tar -xvf /tmp/$TANZU_CLI_PRODUCT_FILE -C /tmp/tanzu

sudo install /tmp/tanzu/v*/$TANZU_CLI /usr/local/bin/tanzu

tanzu version

tanzu config eula accept

tanzu plugin install --group vmware-tap/default:v$TAP_VERSION

tanzu plugin list
