#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: create IAM Roles for Service Accounts

Required Environment Variables:
- AWS_ACCOUNT_ID -- Account ID owning the named IAM Policy
- EKS_CLUSTER_NAME -- (deprecated) cluster on which TAP is being installed (and has been configured to be an OIDC Provider)
- CLUSTER_NAME -- cluster on which TAP is being installed (and has been configured to be an OIDC Provider)

Optional:
- IAM_POLICY_NAME_FOR_TANZU_SYNC -- name of existing IAM Policy granting (at least) read access to AWS Secrets Manager secrets needed for Tanzu Sync
- IAM_POLICY_NAME_FOR_TAP -- name of existing IAM Policy granting (at least) read access to AWS Secrets Manager secrets needed for TAP install
- IAM_ROLE_NAME_FOR_TANZU_SYNC -- name of IAM Role (to be created) which will be used to access Tanzu Sync secrets
- IAM_ROLE_NAME_FOR_TAP -- name of IAM Role (to be created) which will be used to access TAP sensitive values

NOTE: all AWS IAM Policy and IAM Role names must be unique across clusters.

EOF
}

CLUSTER_NAME="${CLUSTER_NAME:-$EKS_CLUSTER_NAME}"

error_msg="Expected env var to be set, but was not."
: "${AWS_ACCOUNT_ID?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

IAM_POLICY_NAME_FOR_TANZU_SYNC=${IAM_POLICY_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--read-tanzu-sync-secrets}
IAM_POLICY_NAME_FOR_TAP=${IAM_POLICY_NAME_FOR_TAP:-${CLUSTER_NAME}--read-tap-secrets}
IAM_ROLE_NAME_FOR_TANZU_SYNC=${IAM_ROLE_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--tanzu-sync-secrets}
IAM_ROLE_NAME_FOR_TAP=${IAM_ROLE_NAME_FOR_TAP:-${CLUSTER_NAME}--tap-install-secrets}

# TODO: replace with AWS CLI-based setup and skip the Service Account creation
eksctl create iamserviceaccount \
  --name tanzu-sync-secrets \
  --namespace tanzu-sync \
  --cluster ${CLUSTER_NAME} \
  --role-name ${IAM_ROLE_NAME_FOR_TANZU_SYNC} \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME_FOR_TANZU_SYNC} \
  --override-existing-serviceaccounts \
  --approve

eksctl create iamserviceaccount \
  --name tap-install-secrets \
  --namespace tap-install \
  --cluster ${CLUSTER_NAME} \
  --role-name ${IAM_ROLE_NAME_FOR_TAP} \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME_FOR_TAP} \
  --override-existing-serviceaccounts \
  --approve
