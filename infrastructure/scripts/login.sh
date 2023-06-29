#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

# GitHub
if [[ "$GIT_AUTH_VIA_SSH_KEY" != true ]]; then
  # use GitHub token for git auth

  echo "export GH_USERNAME=\"$GH_USERNAME\"" >.envrc
  echo "export GH_TOKEN=\"$GH_TOKEN\"" >.envrc
  direnv allow
  gh auth login --hostname github.com

  # NOTE: we can't dynamically add the priv_key via cloud-init so delete since we don't need it
  shred ~/.ssh/priv_key
  rm ~/.ssh/priv_key
fi

# pivnet
pivnet login --api-token="$TANZU_NETWORK_REFRESH_TOKEN"
