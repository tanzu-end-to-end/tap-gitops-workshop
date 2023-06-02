#!/usr/bin/env bash
##

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  echo "Create Tanzu Sync-managed cluster configuration directory tree"
  echo ""
  echo " $0 (cluster-name) (secrets-manager)"
  echo ""
  echo "where:"
  echo "- cluster-name :: name of directory under ./clusters to place cluster configuration."
  echo "- secrets-manager = {aws-secrets-manager,vault,sops} :: which secrets management system secrets are stored in."
  echo ""
}

if [[ ! $# -eq 2 ]]; then
  usage
  exit 1
fi

cluster_name="$1"
secrets_manager="$2"
catalog_dir=".catalog"
tanzu_sync_version="${TS_VERSION:-0.2.0}"
tap_version="${TAP_VERSION:-1.6.0}"

if [[ ! ",aws-secrets-manager,vault,sops," =~ (,${secrets_manager},) ]]; then
  usage
  echo "Error: (secrets-manager); wanted: one of [\"aws-secrets-manager\", "\vault", \"sops\"]; got: \"${secrets_manager}\"."
  exit 2
fi

# remove old tanzu managed directories
if [[ -d "clusters/${cluster_name}/tanzu-sync/app/config/.tanzu-managed" ]]; then
  rm -r clusters/"${cluster_name}"/tanzu-sync/app/config/.tanzu-managed/*
fi

if [[ -d "clusters/${cluster_name}/cluster-config/config/tap-install/.tanzu-managed" ]]; then
  rm -r clusters/"${cluster_name}"/cluster-config/config/tap-install/.tanzu-managed/*
fi

mkdir -p clusters/"${cluster_name}"

# Setup tanzu-sync directory
cp -R ${catalog_dir}/tanzu-sync/${tanzu_sync_version}/${secrets_manager}/ clusters/"${cluster_name}"/tanzu-sync/

# Setup cluster-config directory
mkdir -p clusters/"${cluster_name}"/cluster-config/{config,values}
mkdir -p clusters/"${cluster_name}"/cluster-config/config/tap-install/.tanzu-managed

cp -R ${catalog_dir}/tap-install/${tap_version}/${secrets_manager}/config/.tanzu-managed clusters/"${cluster_name}"/cluster-config/config/tap-install

echo "Created cluster configuration in ./clusters/${cluster_name}."
echo ""
echo "Next steps:"
echo "$ git add . && git commit -m \"Add ${cluster_name}\""
echo "$ git push -u origin"
echo "$ cd clusters/${cluster_name}"
echo "$ less README.md"

# vim:ft=sh
