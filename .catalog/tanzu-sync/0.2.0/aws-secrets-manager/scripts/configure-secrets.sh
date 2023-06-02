#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: configure Tanzu Sync for use with External Secrets Operator (ESO)

Required Environment Variables:
- AWS_ACCOUNT_ID -- Account ID owning the named IAM Policy
- AWS_REGION -- region from where to fetch Secrets Manager secrets
- EKS_CLUSTER_NAME -- (deprecated) cluster on which TAP is being installed
- CLUSTER_NAME -- cluster on which TAP is being installed

Optional:
- IAM_ROLE_NAME_FOR_TANZU_SYNC -- name of IAM Role (to be created) which will be used to access Tanzu Sync secrets
- IAM_ROLE_NAME_FOR_TAP -- name of IAM Role (to be created) which will be used to access TAP sensitive values

EOF
}

CLUSTER_NAME="${CLUSTER_NAME:-$EKS_CLUSTER_NAME}"

error_msg="Expected env var to be set, but was not."
: "${AWS_ACCOUNT_ID?$error_msg}"
: "${AWS_REGION?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

IAM_ROLE_NAME_FOR_TANZU_SYNC=${IAM_ROLE_NAME_FOR_TANZU_SYNC:-${CLUSTER_NAME}--tanzu-sync-secrets}
IAM_ROLE_NAME_FOR_TAP=${IAM_ROLE_NAME_FOR_TAP:-${CLUSTER_NAME}--tap-install-secrets}

# configure
# (see: tanzu-sync/app/config/.tanzu-managed/schema.yaml)
ts_values_path=tanzu-sync/app/values/tanzu-sync-aws-secrets-manager-values.yaml
cat > ${ts_values_path} << EOF
---
secrets:
  eso:
    aws:
      region: ${AWS_REGION}
      tanzu_sync_secrets:
        role_arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME_FOR_TANZU_SYNC}
    remote_refs:
      sync_git:
        # TODO: Fill in your configuration for ssh or basic auth here (see tanzu-sync/app/config/.tanzu-managed/schema--eso.yaml)
      install_registry_dockerconfig:
        dockerconfigjson:
          key: dev/${CLUSTER_NAME}/tanzu-sync/install-registry-dockerconfig
EOF

echo "wrote ESO configuration for Tanzu Sync to: ${ts_values_path}"

tap_install_values_path=cluster-config/values/tap-install-aws-secrets-manager-values.yaml
cat > ${tap_install_values_path} << EOF
---
tap_install:
  secrets:
    eso:
      aws:
        region: ${AWS_REGION}
        tap_install_secrets:
          role_arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME_FOR_TAP}
      remote_refs:
        tap_sensitive_values:
          sensitive_tap_values_yaml:
            key: dev/${CLUSTER_NAME}/tap/sensitive-values.yaml
EOF

echo "wrote AWS Secrets Manager configuration for TAP install to: ${tap_install_values_path}"
echo ""
echo "Please edit '${ts_values_path}' filling in values for each 'TODO' comment"