#!/usr/bin/env bash
set -euo pipefail

# Allow overrides via env, keep sensible defaults
DAILY_SCRATCH_ORG_THRESHOLD="${DAILY_SCRATCH_ORG_THRESHOLD:-15}"
ACTIVE_SCRATCH_ORG_THRESHOLD="${ACTIVE_SCRATCH_ORG_THRESHOLD:-10}"

# Dependencies
for cmd in sf jq; do
  command -v "$cmd" >/dev/null || {
    echo "::error title=Missing dependency::'$cmd' is not installed or not on PATH"
    exit 1
  }
done

# Input (use underscores in env var names)
if [ -z "${DEV_HUB:-}" ]; then
  echo "::error title=Missing Variable::Environment variable 'DEV_HUB' is not set."
  exit 1
fi

tmp_limits_file=$(mktemp)
trap 'rm -f "$tmp_limits_file"' EXIT

sf org list limits --target-org "$DEV_HUB" --json > "$tmp_limits_file"

remainingDailyScratchOrgs=$(jq '.result[] | select(.name=="DailyScratchOrgs").remaining' "$tmp_limits_file") || {
    echo "::error title=JQ Error::Failed to parse DailyScratchOrgs from limits.json"
    exit 1
}

remainingActiveScratchOrgs=$(jq '.result[] | select(.name=="ActiveScratchOrgs").remaining' "$tmp_limits_file") || {
    echo "::error title=JQ Error::Failed to parse ActiveScratchOrgs from limits.json"
    exit 1
}

# Exit if remaining daily scratch orgs are below threshold
if ! [[ "$remainingDailyScratchOrgs" =~ ^[0-9]+$ ]]; then
    echo "::error title=Invalid DailyScratchOrgs Value::Value for DailyScratchOrgs is not a valid number: '$remainingDailyScratchOrgs'"
    exit 1

elif [ "$remainingDailyScratchOrgs" -lt "$DAILY_SCRATCH_ORG_THRESHOLD" ]; then
    echo "::error title=Close to remaining Daily Scratch Org Limit::Remaining DailyScratchOrgs: $remainingDailyScratchOrgs is below threshold of $DAILY_SCRATCH_ORG_THRESHOLD"
    exit 1
fi

# Exit if remaining active scratch orgs are below threshold (10)
if ! [[ "$remainingActiveScratchOrgs" =~ ^[0-9]+$ ]]; then
    echo "::error title=Invalid Value::Remaining ActiveScratchOrgs is not a valid number: $remainingActiveScratchOrgs"
    exit 1
elif [ "$remainingActiveScratchOrgs" -lt "$ACTIVE_SCRATCH_ORG_THRESHOLD" ]; then
    echo "::error title=Close to remaining Active Scratch Orgs::Remaining ActiveScratchOrgs: $remainingActiveScratchOrgs is below threshold of $ACTIVE_SCRATCH_ORG_THRESHOLD"
    exit 1
fi

echo "::notice title=Limits OK::Daily=$remainingDailyScratchOrgs, Active=$remainingActiveScratchOrgs"