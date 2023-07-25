#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

echo " === login.sh === "

if [[ "$GIT_AUTH_VIA_SSH_KEY" != true ]]; then
  # remove private keys since user opted into GitHub Auth
  shred ~/.ssh/priv_key
  rm ~/.ssh/priv_key

  # use GitHub token for git auth via the environment
  echo "export GH_USERNAME=\"$GH_USERNAME\"" >> .envrc
  echo "export GH_TOKEN=\"$GH_TOKEN\"" >> .envrc
  direnv allow

  # validate auth token has required scopes
  gh auth status
fi
