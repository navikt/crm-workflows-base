#!/usr/bin/env bash
set -euo pipefail

keys=""
if [ -n "${CRM_PACKAGE_KEY:-}" ]; then
  echo "::add-mask::$CRM_PACKAGE_KEY"
  
  # Read package aliases robustly (0+ results)
  mapfile -t packageNames < <(jq -r '(.packageAliases // {}) | keys[]?' "$SFDX_PROJECT_PATH") || {
    echo "::error title=JQ Error::Failed to read packageAliases from $SFDX_PROJECT_PATH"
    exit 1
  }

  pairs=()
  for p in "${packageNames[@]}"; do
    pairs+=("$p:$CRM_PACKAGE_KEY")
  done

  if ((${#pairs[@]} > 0)); then
    printf -v keys '%s ' "${pairs[@]}"
    keys=${keys% }  # trim trailing space
  fi
  echo "package-keys=$keys" >> "$GITHUB_OUTPUT"
else
  echo "::notice No package key found, dropping key pair creation"
fi
