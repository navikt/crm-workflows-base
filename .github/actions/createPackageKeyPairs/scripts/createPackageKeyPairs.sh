#!/usr/bin/env bash
set -euo pipefail

# Defaults (can be overridden by the composite action inputs/env)
: "${SFDX_PROJECT_PATH:=sfdx-project.json}"
: "${CRM_PACKAGE_KEY:=}"

# Short-circuit if no key provided
if [[ -z "${CRM_PACKAGE_KEY}" ]]; then
  echo "::notice title=Package keys::No CRM_PACKAGE_KEY provided; skipping key pair creation"
  echo "package-keys=" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Mask the key once (safe to repeat)
echo "::add-mask::$CRM_PACKAGE_KEY"

# Read aliases, filtered by packageKeyConfig:
#  - include alias if packageKeyConfig[alias] != false
#  - if packageKeyConfig is missing or alias not present there, we include it
if ! mapfile -t packageNames < <(
  jq -r '
    (.packageAliases // {}) as $aliases
    | (.packageKeyConfig // {}) as $cfg
    | $aliases
    | keys[]
    | select($cfg[.] != false)
    | .
  ' "$SFDX_PROJECT_PATH"
); then
  echo "::error title=JQ Error::Failed to parse $SFDX_PROJECT_PATH"
  exit 1
fi

pairs=()
for alias in "${packageNames[@]}"; do
  pairs+=("$alias:$CRM_PACKAGE_KEY")
done

keys=""
if ((${#pairs[@]} > 0)); then
  printf -v keys '%s ' "${pairs[@]}"
  keys=${keys% }  # trim trailing space
fi

echo "package-keys=$keys" >> "$GITHUB_OUTPUT"

total_aliases=$(jq -r '(.packageAliases // {}) | keys | length' "$SFDX_PROJECT_PATH")
generated=${#pairs[@]}
skipped=$(( total_aliases - generated ))
echo "::notice title=Package key resolution::Generated $generated pair(s); skipped $skipped"
