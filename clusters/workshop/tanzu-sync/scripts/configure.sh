#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: configure Tanzu Sync for TAP Install

Environment Variables:
- TAP_PKGR_REPO -- URL of OCI registry and repository path to the imgpkg bundle containing the TAP PackageRepository
                   (default: "registry.tanzu.vmware.com/tanzu-application-platform/tap-packages")

EOF
}

if [[ $# -ne 0 ]]; then
  usage
  exit 1
fi

TAP_PKGR_REPO=${TAP_PKGR_REPO:-registry.tanzu.vmware.com/tanzu-application-platform/tap-packages}

# detect remote git repo and upstream branch
remote_branch=$( git status --porcelain=2 --branch | grep "^# branch.upstream" | awk '{ print $3 }' )
remote_name=$( echo $remote_branch | awk -F/ '{ print $1 }' )
remote_url=$( git config --get remote.${remote_name}.url )

# detect cluster name
cluster_name=$( basename ${PWD} )
cluster_config_path=clusters/${cluster_name}/cluster-config

# configure
# (see: tanzu-sync/app/config/.tanzu-managed/schema.yaml)
cat > tanzu-sync/app/values/tanzu-sync.yaml << EOF
---
git:
  url: ${remote_url}
  ref: ${remote_branch}
  sub_path: ${cluster_config_path}
tap_package_repository:
  oci_repository: ${TAP_PKGR_REPO}
EOF

echo "wrote non-sensitive Tanzu Sync configuration to: tanzu-sync/app/values/tanzu-sync.yaml"

cat > cluster-config/values/tap-install-values.yaml << EOF
tap_install:
  package_repository:
    oci_repository: ${TAP_PKGR_REPO}
EOF

echo "wrote non-sensitive TAP Install configuration to: cluster-config/values/tap-install-values.yaml"
echo ""

source tanzu-sync/scripts/configure-secrets.sh

cat << EOF

(refer to https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-gitops-eso.html for next steps)

EOF
