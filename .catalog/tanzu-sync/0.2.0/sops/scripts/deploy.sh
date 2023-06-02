#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

: "${SOPS_AGE_KEY?Expected env var to be set, but was not.}"

kapp deploy -a tanzu-sync \
  -f <(ytt -f tanzu-sync/app/config \
           -f cluster-config/config/tap-install/.tanzu-managed/version.yaml \
           --data-values-file sensitive-values.stdout=<(sops -d tanzu-sync/app/sensitive-values/tanzu-sync-values.sops.yaml) \
           --data-values-file tanzu-sync/app/values/
      ) $@