#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

echo " === configure-vm.sh === "

# create env vars for direnv
cat <<EOF > ~/.envrc
export GH_USERNAME="$1"
export GH_TOKEN="$2"

export TANZU_NETWORK_REFRESH_TOKEN="$3"
export TANZU_REGISTRY_USERNAME="$4"
export TANZU_REGISTRY_PASSWORD="$5"
EOF

/usr/local/bin/tap-gitops-workshop-scripts/install-tools.sh

# reload so brew installed apps are in the PATH
. ~/.profile

# allow and load direnv (https://github.com/direnv/direnv/issues/262)
direnv allow . && eval "$(direnv export bash)"

/usr/local/bin/tap-gitops-workshop-scripts/install-tanzu.sh
/usr/local/bin/tap-gitops-workshop-scripts/login-gh.sh
