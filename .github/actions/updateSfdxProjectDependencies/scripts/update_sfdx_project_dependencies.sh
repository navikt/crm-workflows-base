#!/usr/bin/env bash

set -euo pipefail

# Configurable target org (default to 'org' if not set)
TARGET_ORG="${TARGET_ORG:-org}"
SFDX_PROJECT_PATH="${SFDX_PROJECT_PATH:-sfdx-project.json}"

# Temp files and cleanup
TMP_SFDX=$(mktemp)
TMP_VERSIONS=$(mktemp)
cleanup() { rm -f "$TMP_SFDX" "$TMP_VERSIONS"; }
trap cleanup EXIT

# Ensure we're in a repo with sfdx-project.json
if [ ! -f "$SFDX_PROJECT_PATH" ]; then
  echo "::error title=Missing file::$SFDX_PROJECT_PATH not found."
  exit 1
fi

# Backup original
cp "$SFDX_PROJECT_PATH" "$TMP_SFDX"

# Get installed packages (filter to no namespace, build {package: version} map)
if ! sf package installed list --target-org "$TARGET_ORG" --json > "$TMP_VERSIONS.raw"; then
  echo "::error title=Salesforce CLI failed::sf package installed list failed for org '$TARGET_ORG'"
  exit 1
fi

jq -e '
  .result
  | map(select(.SubscriberPackageNamespace == null))
  | map({key: .SubscriberPackageName, value: .SubscriberPackageVersionNumber})
  | from_entries
' "$TMP_VERSIONS.raw" > "$TMP_VERSIONS"

# Update dependencies.versionNumber for matching packages
jq --slurpfile versions "$TMP_VERSIONS" '
  .packageDirectories |=
  (map(
    if (.dependencies // empty) != [] then
      .dependencies |=
      (map(
        if (.package and ($versions[0][.package] // null)) then
          .versionNumber = $versions[0][.package]
        else .
        end
      ))
    else .
    end
  ))
' "$TMP_SFDX" > "$SFDX_PROJECT_PATH"

# Check for changes
isChanged=$(git status --porcelain "$SFDX_PROJECT_PATH" | wc -l)

if [ "$isChanged" -gt 0 ]; then
  updated=true
else
  updated=false
fi

echo "::notice title=Updated dependencies::targetOrg=$TARGET_ORG, file=$SFDX_PROJECT_PATH, changed=$updated"

echo "updated=$updated" >> "$GITHUB_OUTPUT"