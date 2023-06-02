#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: delete Vault Policies and AppRoles governing access to Tanzu Sync and TAP Install secrets

Required:
- VAULT_ADDR -- Vault server which is hosting the secrets
- CLUSTER_NAME -- cluster on which TAP is being installed

Optional:
- VAULT_TOKEN -- Vault token authorized to delete policies
- VAULT_POLICY_NAME_FOR_TANZU_SYNC -- name of existing Vault Policy granting (at least) read access to secrets needed for Tanzu Sync
- VAULT_POLICY_NAME_FOR_TAP -- name of existing Vault Policy granting (at least) read access to secrets needed for TAP install

EOF
}
error_msg="Expected env var to be set, but was not."
: "${VAULT_ADDR?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

VAULT_POLICY_NAME_FOR_TANZU_SYNC=${VAULT_POLICY_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--read-tanzu-sync-secrets}
VAULT_POLICY_NAME_FOR_TAP=${VAULT_POLICY_NAME_FOR_TAP:-${CLUSTER_NAME}--read-tap-install-secrets}

vault policy delete ${VAULT_POLICY_NAME_FOR_TANZU_SYNC}
vault policy delete ${VAULT_POLICY_NAME_FOR_TAP}
