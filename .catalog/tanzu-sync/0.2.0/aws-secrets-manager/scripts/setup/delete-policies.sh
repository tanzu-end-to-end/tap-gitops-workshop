#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: delete IAM Policies governing access to Tanzu Sync and TAP Install secrets

Required Environment Variables:
- AWS_ACCOUNT_ID -- Account ID owning the named IAM Policy
- EKS_CLUSTER_NAME -- (deprecated) cluster on which TAP is being installed (and has been configured to be an OIDC Provider)
- CLUSTER_NAME -- cluster on which TAP is being installed (and has been configured to be an OIDC Provider)

Optional (if unset, default values are deleted):
- IAM_POLICY_NAME_FOR_TANZU_SYNC -- name of existing IAM Policy granting (at least) read access to AWS Secrets Manager secrets needed for Tanzu Sync
- IAM_POLICY_NAME_FOR_TAP -- name of existing IAM Policy granting (at least) read access to AWS Secrets Manager secrets needed for TAP install

EOF
}

CLUSTER_NAME="${CLUSTER_NAME:-$EKS_CLUSTER_NAME}"

error_msg="Expected env var to be set, but was not."
: "${AWS_ACCOUNT_ID?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

IAM_POLICY_NAME_FOR_TANZU_SYNC=${IAM_POLICY_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--read-tanzu-sync-secrets}
IAM_POLICY_NAME_FOR_TAP=${IAM_POLICY_NAME_FOR_TAP:-${CLUSTER_NAME}--read-tap-secrets}

set -x
aws iam delete-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME_FOR_TANZU_SYNC}"
aws iam delete-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME_FOR_TAP}"
