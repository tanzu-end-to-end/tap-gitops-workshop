#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  set +x
  echo "$0 :: delete IAM Role for Service Account"
  echo "Inputs:"
  echo "- EKS_CLUSTER_NAME -- cluster on which TAP is being installed (and has been configured to be an OIDC Provider"
}

error_msg="Expected env var to be set, but was not."
: "${EKS_CLUSTER_NAME?$error_msg}"

set -x
eksctl delete iamserviceaccount \
  --cluster ${EKS_CLUSTER_NAME} \
  --name tanzu-sync-secrets \
  --namespace tanzu-sync
  
eksctl delete iamserviceaccount \
  --cluster ${EKS_CLUSTER_NAME} \
  --name tap-install-secrets \
  --namespace tap-install
