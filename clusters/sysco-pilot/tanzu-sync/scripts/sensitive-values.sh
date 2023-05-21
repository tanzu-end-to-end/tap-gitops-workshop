#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

function usage() {
  >&2 cat << EOF
$0 :: configure Tanzu Sync for use with Secret OPerationS (SOPS)" 
 
Environment Variables:
- INSTALL_REGISTRY_HOSTNAME -- hostname of OCI Registry containing TAP packages
- INSTALL_REGISTRY_USERNAME -- username of account to OCI Registry containing TAP packages
- INSTALL_REGISTRY_PASSWORD -- password of account to OCI Registry containing TAP packages
- GIT_SSH_PRIVATE_KEY       -- private key with at least read access to repo in github
- GIT_KNOWN_HOSTS           -- known host fingerprint entry matching the type of SSH key
- SOPS_AGE_KEY              -- Age identity recipient of the sensitive TAP values
 
EOF
}

error_msg="Expected env var to be set, but was not."
: "${INSTALL_REGISTRY_USERNAME?$error_msg}"
: "${INSTALL_REGISTRY_PASSWORD?$error_msg}"
: "${INSTALL_REGISTRY_HOSTNAME?$error_msg}"
: "${GIT_SSH_PRIVATE_KEY?$error_msg}"
: "${GIT_KNOWN_HOSTS?$error_msg}"
: "${SOPS_AGE_KEY?$error_msg}"

# pass in the multi-line strings as a data-values file as it properly
# escapes the multi-line values.

sensitive_tanzu_sync_values=$(cat << EOF
---
secrets:
  sops:
    age_key: | 
$(echo "${SOPS_AGE_KEY}" | awk '{printf "      %s\n", $0}')
    registry:
      hostname: "${INSTALL_REGISTRY_HOSTNAME}"
      username: "${INSTALL_REGISTRY_USERNAME}"
      password: "${INSTALL_REGISTRY_PASSWORD}"
    git:
      ssh:
        private_key: | 
$(echo "$GIT_SSH_PRIVATE_KEY" | awk '{printf "          %s\n", $0}')
        known_hosts: |
$(echo "$GIT_KNOWN_HOSTS" | awk '{printf "          %s\n", $0}')
EOF
)

# Do not display sensitive values to the terminal.
if [[ -t 1 ]]; then
  >&2 echo "Sensitive values are present; will be used by ./tanzu-sync/scripts/deploy.sh"
else
  echo "${sensitive_tanzu_sync_values}"
fi
