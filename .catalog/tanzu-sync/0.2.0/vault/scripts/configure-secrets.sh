#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: configure Tanzu Sync for use with External Secrets Operator (ESO)

Required Environment Variables:
- VAULT_ADDR -- Vault server address
- CLUSTER_NAME -- name of cluster on which TAP is being installed

Optional:
- VAULT_TOKEN -- Vault token to access server
- VAULT_ROLE_NAME_FOR_TANZU_SYNC -- name of Vault Role (to be created) which will be used to access Tanzu Sync secrets
- VAULT_ROLE_NAME_FOR_TAP -- name of Vault Role (to be created) which will be used to access TAP sensitive values

EOF
}

error_msg="Expected env var to be set, but was not."
: "${VAULT_ADDR?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

VAULT_ROLE_NAME_FOR_TANZU_SYNC=${VAULT_ROLE_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--tanzu-sync-secrets}
VAULT_ROLE_NAME_FOR_TAP=${VAULT_ROLE_NAME_FOR_TAP:-${CLUSTER_NAME}--tap-install-secrets}

# configure
# (see: tanzu-sync/app/config/.tanzu-managed/schema.yaml)
ts_values_path=tanzu-sync/app/values/tanzu-sync-vault-values.yaml
cat > ${ts_values_path} << EOF
---
secrets:
  eso:
    vault:
      server: ${VAULT_ADDR}
      auth:
        kubernetes:
          mountPath: ${CLUSTER_NAME}
          role: ${VAULT_ROLE_NAME_FOR_TANZU_SYNC}
    remote_refs:
      sync_git:
        # TODO: Fill in your configuration for ssh or basic auth here (see tanzu-sync/app/config/.tanzu-managed/schema--eso.yaml)
      install_registry_dockerconfig:
        dockerconfigjson:
          key: secret/dev/${CLUSTER_NAME}/tanzu-sync/install-registry-dockerconfig
EOF

echo "wrote ESO configuration for Tanzu Sync to: ${ts_values_path}"

tap_install_values_path=cluster-config/values/tap-install-vault-values.yaml
cat > ${tap_install_values_path} << EOF
---
tap_install:
  secrets:
    eso:
      vault:
        server: ${VAULT_ADDR}
        auth:
          kubernetes:
            mountPath: ${CLUSTER_NAME}
            role: ${VAULT_ROLE_NAME_FOR_TAP}
      remote_refs:
        tap_sensitive_values:
          sensitive_tap_values_yaml:
            key: secret/dev/${CLUSTER_NAME}/tap/sensitive-values.yaml
EOF

echo "wrote Vault configuration for TAP install to: ${tap_install_values_path}"
echo ""
echo "Please edit '${ts_values_path}' filling in values for each 'TODO' comment"