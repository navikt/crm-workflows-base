# Sync Workflows

This reusable workflow syncs selected workflow-related files from `navikt/crm-workflows-base` into the target repository and opens or updates a pull request when changes are detected.

## Steps

### Checkout target repo

Checks out the target repository with write access so changes can be committed.

### Checkout platform repo

Checks out `navikt/crm-workflows-base` at the selected `ref` and only fetches the files that should be synced.

### Sync selected files

Copies these files from the platform source into the target repository:

- `.github/dependabot.yml`
- `.github/workflows/automergeDependabot.yml`

Then compares the files and records whether anything changed.

### Create Pull Request

If changes are detected, creates or updates a pull request using the configured branch, title and commit message.

## Inputs

- `branch_name` Optional. Branch name for the update PR. Default: `platform/sync-workflows`
- `pull_request_title` Optional. Title for the update PR. Default: `Sync github workflow files navikt/crm-workflows-base`
- `commit_message` Optional. Commit message for the sync commit. Default: `chore(workflows): Sync workflow files from navikt/crm-workflows-base`
- `ref` Optional. Git ref (branch, tag, or commit) to sync from. Default: `main`

## Secrets

- `PLATFORM_TOKEN_APP_ID` Required. GitHub App ID used to generate a scoped token.
- `PLATFORM_TOKEN_APP_PRIVATE_KEY` Required. Private key for the GitHub App.

## Permissions

The GITHUB_TOKEN requires minimal read-only permissions at the job level. Write access for pushing changes and creating pull requests is handled by the GitHub App token generated at runtime:

- `contents: read`
- `pull-requests: read`

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/workflow-sync.yml@<sha/version>
with:
  branch_name: platform/sync-workflows
  pull_request_title: Sync github workflow files navikt/crm-workflows-base
  commit_message: chore(workflows): Sync workflow files from navikt/crm-workflows-base
  ref: main
secrets:
  PLATFORM_TOKEN_APP_ID: ${{ secrets.PLATFORM_TOKEN_APP_ID }}
  PLATFORM_TOKEN_APP_PRIVATE_KEY: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}
```

## Full Example

```yml
name: Sync Workflows

on:
  schedule:
    - cron: "0 3 * * *"
  workflow_dispatch:

permissions: {}
concurrency:
  group: sync-workflows-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false

jobs:
  sync-workflows:
    name: Sync Workflow Files
    uses: navikt/crm-workflows-base/.github/workflows/workflow-sync.yml@<sha/version>
    permissions:
      contents: read
      pull-requests: read
    secrets:
      PLATFORM_TOKEN_APP_ID: ${{ secrets.PLATFORM_TOKEN_APP_ID }}
      PLATFORM_TOKEN_APP_PRIVATE_KEY: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}
```
