#!/usr/bin/env bash
# Script: createPackageKeyPairs.sh
# Purpose: Output space-separated package:key pairs for password-protected second-generation package
#          dependencies defined in one or more packageDirectories in an sfdx-project.json file.
#
# Features:
#  * Supports multiple packageDirectories (monorepos) and deduplicates packages, keeping the latest version.
#  * Skips dependency entries missing a package or versionNumber.
#  * Allows configuration of Dev Hub alias and the --modified-last-days window.
#  * Optional debug logging.
#  * Deterministic sorted output for reproducibility.
#  * Graceful handling when there are no matching protected packages (empty output, exit 0).
#
# Usage:
#   Basic:   ./createPackageKeyPairs.sh -p sfdx-project.json -k <installKey>
#   Extended: ./createPackageKeyPairs.sh -p sfdx-project.json -k <installKey> \
#              --devhub myDevHub --modified-last-days 120 --debug
#
# Options:
#   -p, --sfdx-project-path <file>   Path to sfdx-project.json (required)
#   -k, --package-key <key>          Package installation key (required)
#       --devhub <alias>             Dev Hub alias/username (default: devhub)
#       --modified-last-days <n>     Lookback window for sf query (default: 1000)
#       --debug                      Enable debug logging to stderr
#   -h, --help                       Show help/usage
#
# Output:
#   Prints space-separated pairs like: pkgA:key pkgB:key
#   Prints nothing if no password-protected matching versions found.
#
# Requirements:
#   bash 4+, jq, sf CLI (authenticated to the target Dev Hub), read access to sfdx-project.json.
#
# Exit Codes:
#   0 success (even if no keys generated)
#   1 usage / validation / tooling error
#   2 sf CLI query failure

set -euo pipefail

# Trap unexpected errors to aid debugging (excluding deliberate exits via fail())
on_err() {
  local status=$?
  echo "Error: Script failed at line ${LINENO}. Last command: ${BASH_COMMAND}" >&2
  exit $status
}
trap on_err ERR

# --- Helpers -----------------------------------------------------------------

fail() { echo "Error: $*" >&2; exit 1; }
# Debug helper: never return non-zero so ERR trap is not triggered by a disabled debug call.
debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG] $*" >&2
  fi
  return 0
}

# Compare two dot-delimited numeric version strings.
# Returns 0 (true) if v1 >= v2, 1 otherwise (so usable in if version_ge a b; then ...)
version_ge() {
  local v1="$1" v2="$2"
  # Validate numeric-dot format (allow digits and dots only)
  [[ $v1 =~ ^[0-9]+(\.[0-9]+)*$ ]] || fail "Non-numeric version part in '$v1'"
  [[ $v2 =~ ^[0-9]+(\.[0-9]+)*$ ]] || fail "Non-numeric version part in '$v2'"
  IFS='.' read -ra v1_parts <<< "$v1"
  IFS='.' read -ra v2_parts <<< "$v2"
  for ((i=0; i<${#v1_parts[@]} || i<${#v2_parts[@]}; i++)); do
    local p1="${v1_parts[i]:-0}" p2="${v2_parts[i]:-0}"
    if (( p1 > p2 )); then return 0; fi
    if (( p1 < p2 )); then return 1; fi
  done
  return 0
}

print_help() {
  cat <<'EOF'
createPackageKeyPairs.sh

Generate space-separated package:key pairs for password-protected (IsPasswordProtected=true) 2GP dependencies
declared in one or more packageDirectories of an sfdx-project.json.

Usage:
  ./createPackageKeyPairs.sh -p sfdx-project.json -k <installKey> [options]

Required:
  -p, --sfdx-project-path <file>   Path to sfdx-project.json
  -k, --package-key <key>          Installation key applied to protected packages

Options:
      --devhub <alias>             Dev Hub alias/username (default: devhub)
      --modified-last-days <n>     Lookback window for sf query (default: 1000)
      --debug                      Verbose debug logging to stderr
  -q, --quiet                      Suppress non-error informational summary lines
      --latest-fallback            If exact build not found (or version uses .LATEST), use highest protected build
  -h, --help                       Show this help and exit

Behavior:
  * Monorepo aware: merges dependencies across directories, keeping highest version.
  * Exact version match by default (Version must equal dependency version).
  * Supports dependency versions ending with .LATEST (e.g. 1.2.3.LATEST) mapping to highest protected build.
  * With --latest-fallback, if an exact build is absent, highest protected build for same Major.Minor.Patch is used.
  * Output is deterministic (sorted by package name).
  * Empty stdout if no protected matches (exit 0).

Exit Codes:
  0 success (keys may be empty)
  1 usage/validation/tooling error
  2 sf CLI query failure

Examples:
  ./createPackageKeyPairs.sh -p sfdx-project.json -k KEY
  ./createPackageKeyPairs.sh -p sfdx-project.json -k KEY --devhub MyHub --modified-last-days 180 --debug
  ./createPackageKeyPairs.sh -p sfdx-project.json -k KEY -q
EOF
}

# --- Option Parsing ----------------------------------------------------------

SFDX_PROJECT_PATH=""
CRM_PACKAGE_KEY=""
DEVHUB_ALIAS="devhub"
MODIFIED_DAYS="1000"
DEBUG="false"
QUIET="false"
LATEST_FALLBACK="false"

while getopts "p:k:hq-:" opt; do
  case $opt in
    p) SFDX_PROJECT_PATH="$OPTARG" ;;
    k) CRM_PACKAGE_KEY="$OPTARG" ;;
    h) print_help; exit 0 ;;
    q) QUIET="true" ;;
    -)
      case "$OPTARG" in
        sfdx-project-path) SFDX_PROJECT_PATH="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
        package-key) CRM_PACKAGE_KEY="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
        devhub) DEVHUB_ALIAS="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
        modified-last-days) MODIFIED_DAYS="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
        debug) DEBUG="true" ;;
        latest-fallback) LATEST_FALLBACK="true" ;;
        quiet) QUIET="true" ;;
        help) print_help; exit 0 ;;
        *) fail "Invalid option --$OPTARG" ;;
      esac
      ;;
    *) fail "Usage: $0 -p <sfdx-project.json> -k <key> [--devhub alias] [--modified-last-days N] [--debug] [--quiet]" ;;
  esac
done

[[ -n "$SFDX_PROJECT_PATH" && -n "$CRM_PACKAGE_KEY" ]] || fail "Missing required options. Use -h for help."
[[ -f "$SFDX_PROJECT_PATH" ]] || fail "File not found: $SFDX_PROJECT_PATH"
command -v jq >/dev/null || fail "jq not installed or not in PATH"
command -v sf >/dev/null || fail "sf CLI not installed or not in PATH"
[[ "$MODIFIED_DAYS" =~ ^[0-9]+$ ]] || fail "--modified-last-days must be numeric"

debug "Using Dev Hub alias: $DEVHUB_ALIAS"
debug "Modified last days: $MODIFIED_DAYS"

# --- Dependency Extraction ----------------------------------------------------

declare -A packageVersions=()
numDirs=$(jq '.packageDirectories | length' "$SFDX_PROJECT_PATH") || fail "Unable to parse packageDirectories"
debug "packageDirectories count: $numDirs"

for ((i=0; i<numDirs; i++)); do
  debug "Processing packageDirectory index $i"
  # Use ? to avoid error on missing dependencies; filter only entries with both keys.
  mapfile -t deps < <(jq -r ".packageDirectories[$i].dependencies[]? | select(.package != null and .versionNumber != null) | \"\(.package):\(.versionNumber)\"" "$SFDX_PROJECT_PATH" || true)
  ((${#deps[@]}==0)) && { debug "No dependencies in directory $i"; continue; }
  for entry in "${deps[@]}"; do
    pkg=${entry%%:*}
    ver=${entry#*:}
    [[ -z "$pkg" || -z "$ver" ]] && { debug "Skipping invalid entry '$entry'"; continue; }
    if [[ -z "${packageVersions[$pkg]:-}" ]]; then
      packageVersions["$pkg"]="$ver"
      debug "Set $pkg -> $ver"
    else
      if version_ge "$ver" "${packageVersions[$pkg]}"; then
        debug "Update $pkg: ${packageVersions[$pkg]} -> $ver"
        packageVersions["$pkg"]="$ver"
      else
        debug "Keep $pkg: existing ${packageVersions[$pkg]} >= $ver"
      fi
    fi
  done
done

if ((${#packageVersions[@]}==0)); then
  debug "No valid dependency packages found. Exiting with empty output."
  exit 0
fi

# Deterministic ordering
mapfile -t packageNames < <(printf '%s\n' "${!packageVersions[@]}" | sort)
packagesFlag=$(IFS=,; echo "${packageNames[*]}")
debug "Package query list: $packagesFlag"

# --- SF Query -----------------------------------------------------------------

sf_args=(package version list -v "$DEVHUB_ALIAS" --modified-last-days "$MODIFIED_DAYS" --json --packages "$packagesFlag")
debug "Running: sf ${sf_args[*]}"
# Execute sf command robustly without letting set -e swallow the error before we handle it.
{
  set +e
  sf_output=$(sf "${sf_args[@]}" 2> >(tee /tmp/sf_err.log >&2))
  sf_rc=$?
  set -e
}
if (( sf_rc != 0 )); then
  echo "Error: sf package version list command failed (exit $sf_rc)" >&2
  if [[ -s /tmp/sf_err.log ]]; then
    echo "-- sf stderr --" >&2
    sed 's/^/  /' /tmp/sf_err.log >&2 || true
  else
    echo "(No stderr captured from sf)" >&2
  fi
  echo "Invoked command: sf ${sf_args[*]}" >&2
  echo "Packages flag: $packagesFlag" >&2
  [[ "$DEBUG" == "true" ]] && sf --version >&2 || true
  exit 2
fi
response="$sf_output"

# Validate JSON status
status=$(echo "$response" | jq -r '.status // empty')
[[ "$status" == "0" ]] || fail "sf response status not 0 (status=$status)"

result_len=$(echo "$response" | jq '.result | length')
debug "sf returned $result_len versions"
debug "Indexing sf response for faster lookups and latest build selection"
# Pre-index: Package2Name|Version|IsPasswordProtected
mapfile -t index_lines < <(echo "$response" | jq -r '.result[] | "\(.Package2Name)|\(.Version)|\(.IsPasswordProtected)"')
declare -A protectedExact
declare -A protectedLatest  # key: pkg|major.minor.patch -> highest build version string

for line in "${index_lines[@]}"; do
  pkgName="${line%%|*}";
  rest="${line#*|}"; verPart="${rest%%|*}"; protFlag="${line##*|}";
  if [[ "$protFlag" != "true" ]]; then
    continue
  fi
  protectedExact["$pkgName|$verPart"]=1
  # Split version into components major.minor.patch.build
  IFS='.' read -r maj min pat bld <<< "$verPart"
  triple="$maj.$min.$pat"
  currentBest="${protectedLatest["$pkgName|$triple"]:-}"
  if [[ -z "$currentBest" ]]; then
    protectedLatest["$pkgName|$triple"]="$verPart"
  else
    # Compare builds numerically (assuming same triple)
    IFS='.' read -r _ _ _ existingBuild <<< "$currentBest"
    if (( bld > existingBuild )); then
      protectedLatest["$pkgName|$triple"]="$verPart"
    fi
  fi
done

pairs=()
fallback_used=0
for pkg in "${packageNames[@]}"; do
  depVersion="${packageVersions[$pkg]}"
  if [[ $depVersion == *.LATEST ]]; then
    # Resolve .LATEST explicit syntax
    base="${depVersion%.LATEST}"
    IFS='.' read -r maj min pat <<< "$base"
    triple="$maj.$min.$pat"
    latestProt="${protectedLatest["$pkg|$triple"]:-}"
    if [[ -n "$latestProt" ]]; then
      pairs+=("$pkg:$CRM_PACKAGE_KEY")
      ((fallback_used++))
      debug "Resolved $pkg@$depVersion -> $latestProt (LATEST)"
      continue
    else
      debug "No protected builds found for $pkg triple $triple (.LATEST)"
      continue
    fi
  fi

  if [[ -n "${protectedExact["$pkg|$depVersion"]:-}" ]]; then
    pairs+=("$pkg:$CRM_PACKAGE_KEY")
    debug "Protected: $pkg@$depVersion (exact)"
    continue
  fi

  if [[ "$LATEST_FALLBACK" == "true" ]]; then
    IFS='.' read -r maj min pat _build <<< "$depVersion"  # build component not used in fallback selection
    triple="$maj.$min.$pat"
    latestProt="${protectedLatest["$pkg|$triple"]:-}"
    if [[ -n "$latestProt" ]]; then
      pairs+=("$pkg:$CRM_PACKAGE_KEY")
      ((fallback_used++))
      debug "Fallback used for $pkg@$depVersion -> $latestProt"
      continue
    fi
  fi
  debug "Not protected or not found: $pkg@$depVersion"
done

if ((${#pairs[@]}==0)); then
  [[ "$DEBUG" == "true" ]] && echo "[DEBUG] No password-protected matching versions found." >&2
  echo ""  # explicit empty output
  if [[ "$DEBUG" != "true" && "$QUIET" != "true" ]]; then
    echo "Info: 0 protected versions matched" >&2
  fi
  exit 0
fi

matched_count=${#pairs[@]}
[[ "$DEBUG" == "true" && $fallback_used -gt 0 ]] && echo "[DEBUG] Fallback resolutions used: $fallback_used" >&2
if [[ "$DEBUG" != "true" && "$QUIET" != "true" ]]; then
  echo "Info: $matched_count protected versions matched" >&2
fi
printf '%s ' "${pairs[@]}" | sed 's/ $//' 
exit 0