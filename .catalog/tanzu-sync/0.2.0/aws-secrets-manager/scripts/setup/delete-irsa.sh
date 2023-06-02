#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  set +x
  echo "$0 :: delete IAM Role for Service Account"
  echo "Inputs:"
  echo "- EKS_CLUSTER_NAME -- (deprecated) cluster on which TAP is being installed (and has been configured to be an OIDC Provider"
  echo "- CLUSTER_NAME -- cluster on which TAP is being installed (and has been configured to be an OIDC Provider"
}

CLUSTER_NAME="${CLUSTER_NAME:-$EKS_CLUSTER_NAME}"

error_msg="Expected env var to be set, but was not."
: "${CLUSTER_NAME?$error_msg}"

set -x
eksctl delete iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --name tanzu-sync-secrets \
  --namespace tanzu-sync
  
eksctl delete iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --name tap-install-secrets \
  --namespace tap-install
