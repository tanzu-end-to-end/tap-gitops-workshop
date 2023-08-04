#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

echo " === login-gh.sh === "

# validate auth token has required scopes via $GH_TOKEN env var
# gh auth login will exit code 1 if run (https://github.com/cli/cli/issues/7008)
gh auth status

git config --global user.name "$GH_USERNAME"

# setup credential helpers
gh auth setup-git
