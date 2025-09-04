#!/usr/bin/env bash
set -euo pipefail

# Dependencies
for cmd in sfp jq; do
  command -v "$cmd" >/dev/null || {
    echo "::error title=Missing dependency::'$cmd' is not installed or not on PATH"
    exit 1
  }
done

# Inputs and defaults
SFDX_PROJECT_PATH="${SFDX_PROJECT_PATH:-$GITHUB_WORKSPACE/sfdx-project.json}"

if [ ! -f "$SFDX_PROJECT_PATH" ]; then
  echo "::error title=Missing File::sfdx-project.json not found at '$SFDX_PROJECT_PATH'"
  exit 1
fi

if [ -z "${DEV_HUB:-}" ]; then
  echo "::error title=Missing Variable::Environment variable 'DEV_HUB' is not set."
  exit 1
fi

if [ -z "${POOL_CONFIG_PATH:-}" ]; then
  echo "::error title=Missing Variable::Environment variable 'POOL_CONFIG_PATH' is not set."
  exit 1
fi

if [ ! -f "$POOL_CONFIG_PATH" ]; then
  echo "::error title=Missing File::Pool config not found at '$POOL_CONFIG_PATH'"
  exit 1
fi

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

else
  echo "::notice No package key found, dropping key pair creation"
fi

# Prepare Pool (conditionally add --keys)
args=(pool prepare --poolconfig "$POOL_CONFIG_PATH" --targetdevhubusername "$DEV_HUB")
if [ -n "$keys" ]; then
  args+=(--keys "$keys")
fi

sfp "${args[@]}"