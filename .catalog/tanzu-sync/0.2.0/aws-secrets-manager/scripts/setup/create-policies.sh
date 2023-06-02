#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: create IAM Policies governing access to Tanzu Sync and TAP Install secrets

Required:
- AWS_ACCOUNT_ID -- Account ID owning the named IAM Policy (e.g. 66512345684)
- AWS_REGION -- region to connect Secrets Manager for secrets (e.g. us-west-2)
- EKS_CLUSTER_NAME -- (deprecated) cluster on which TAP is being installed (and has been configured to be an OIDC Provider)
- CLUSTER_NAME -- cluster on which TAP is being installed (and has been configured to be an OIDC Provider)

Optional:
- IAM_POLICY_NAME_FOR_TANZU_SYNC -- name of existing IAM Policy granting (at least) read access to AWS Secrets Manager secrets needed for Tanzu Sync
- IAM_POLICY_NAME_FOR_TAP -- name of existing IAM Policy granting (at least) read access to AWS Secrets Manager secrets needed for TAP install
- ASM_RESOURCE_ID_FOR_TANZU_SYNC -- resource ID portion of ARN for Secrets Manager Secret(s) needed for Tanzu Sync (may contain wildcards)
- ASM_RESOURCE_ID_FOR_TAP -- resource ID portion of ARN for Secrets Manager Secret(s) needed for TAP install (may contain wildcards)

NOTE: all AWS IAM Policy names must be unique across clusters.

EOF
}

CLUSTER_NAME="${CLUSTER_NAME:-$EKS_CLUSTER_NAME}"

error_msg="Expected env var to be set, but was not."
: "${AWS_ACCOUNT_ID?$error_msg}"
: "${AWS_REGION?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

IAM_POLICY_NAME_FOR_TANZU_SYNC=${IAM_POLICY_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--read-tanzu-sync-secrets}
IAM_POLICY_NAME_FOR_TAP=${IAM_POLICY_NAME_FOR_TAP:-${CLUSTER_NAME}--read-tap-secrets}
ASM_RESOURCE_ID_FOR_TANZU_SYNC=${ASM_RESOURCE_ID_FOR_TANZU_SYNC:-"dev/${CLUSTER_NAME}/tanzu-sync/*"}
ASM_RESOURCE_ID_FOR_TAP=${ASM_RESOURCE_ID_FOR_TAP:-"dev/${CLUSTER_NAME}/tap/*"}

read_tanzu_sync_secrets=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:${ASM_RESOURCE_ID_FOR_TANZU_SYNC}"
            ]
        }
    ]
}
EOF
)

read_tap_install_secrets=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:${ASM_RESOURCE_ID_FOR_TAP}"
            ]
        }
    ]
}
EOF
)

aws iam create-policy --policy-name ${IAM_POLICY_NAME_FOR_TANZU_SYNC} --policy-document "$(echo "${read_tanzu_sync_secrets}")"
aws iam create-policy --policy-name ${IAM_POLICY_NAME_FOR_TAP} --policy-document "$(echo "${read_tap_install_secrets}")"

