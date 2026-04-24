# Automerge Dependabot PRs

This workflow automatically merges open Dependabot pull requests. It runs on a schedule (weekdays at 04:30 UTC), can be triggered manually, and can also be called from other workflows.

Merges are skipped during blackout periods: weekends, all of July, and December 20 – January 5.

## Steps

### Create GitHub App token

Generates a short-lived installation token for the GitHub App used to authenticate merge and approval operations.

### Automerge Dependabot PRs

Runs [`navikt/automerge-dependabot`](https://github.com/navikt/automerge-dependabot) to find open Dependabot PRs, auto-approve them, and merge them using the squash strategy — provided all required checks pass and the current time is outside the configured blackout periods.

## Secrets

- `secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY` Private key for the GitHub App used to generate the installation token. Required.

## Permissions

| Permission      | Level   | Reason                                          |
| --------------- | ------- | ----------------------------------------------- |
| `contents`      | `write` | Required to perform the merge commit            |
| `pull-requests` | `write` | Required to merge (and auto-approve) PRs        |
| `checks`        | `read`  | Required to read check runs before merging      |
| `statuses`      | `read`  | Required to read commit statuses before merging |

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/automergeDependabot.yml@main
  with:
    # GitHub App client ID
    # Required: false (falls back to vars.PLATFORM_TOKEN_APP_ID)
    # Type: string
    PLATFORM_TOKEN_APP_ID: ''
  secrets:
    PLATFORM_TOKEN_APP_PRIVATE_KEY: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}
```

## Full Example

```yml
name: Automerge Dependabot PRs

on:
  schedule:
    - cron: "30 4 * * 1-5"
  workflow_dispatch:

permissions: {}

jobs:
  automerge:
    uses: navikt/crm-workflows-base/.github/workflows/automergeDependabot.yml@main
    with:
      PLATFORM_TOKEN_APP_ID: ${{ vars.PLATFORM_TOKEN_APP_ID }}
    secrets:
      PLATFORM_TOKEN_APP_PRIVATE_KEY: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}
```
