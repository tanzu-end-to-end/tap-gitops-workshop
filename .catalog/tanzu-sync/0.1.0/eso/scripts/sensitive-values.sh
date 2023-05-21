#!/usr/bin/env bash
#
# ESO does not supply sensitive values directly to Tanzu Sync

# If displaying to tty, report no values will be rendered when piped.
if [[ -t 1 ]]; then
  >&2 echo "NO sensitive values are present (nor required)."
else
  echo "{}"
fi
