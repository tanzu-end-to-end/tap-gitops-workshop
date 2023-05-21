#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  set +x
  echo "Inputs:"
  echo "- INSTALL_REGISTRY_HOSTNAME -- hostname of OCI Registry containing TAP packages"
  echo "- INSTALL_REGISTRY_USERNAME -- username of account to OCI Registry containing TAP packages"
  echo "- INSTALL_REGISTRY_PASSWORD -- password of account to OCI Registry containing TAP packages"
  echo ""
}

error_msg="Expected env var to be set, but was not."
: "${INSTALL_REGISTRY_USERNAME?$error_msg}"
: "${INSTALL_REGISTRY_PASSWORD?$error_msg}"
: "${INSTALL_REGISTRY_HOSTNAME?$error_msg}"

kubectl apply \
  -f <(ytt -f tanzu-sync/bootstrap/ \
           -v registry.hostname="${INSTALL_REGISTRY_HOSTNAME}" \
           -v registry.username="${INSTALL_REGISTRY_USERNAME}" \
           -v registry.password="${INSTALL_REGISTRY_PASSWORD}" \
      ) $@

