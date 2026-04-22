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
- `commit_mesage` Optional. Commit message for the sync commit. Default: `chore(workflows): Sync workflow files from navikt/crm-workflows-base`
- `ref` Optional. Git ref (branch, tag, or commit) to sync from. Default: `main`

## Secrets

- `TOKEN` Required. Token used for checkout and PR creation.

## Permissions

The workflow requires these job-level permissions:

- `contents: write`
- `pull-requests: write`

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/workflow-sync.yml@<sha/version>
with:
  branch_name: platform/sync-workflows
  pull_request_title: Sync github workflow files navikt/crm-workflows-base
  commit_mesage: chore(workflows): Sync workflow files from navikt/crm-workflows-base
  ref: main
secrets:
  TOKEN: ${{ secrets.GITHUB_TOKEN }}
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
  get-token:
    name: Get GitHub App Token
    runs-on: ubuntu-latest
    outputs:
      token: ${{ steps.app-token.outputs.token }}
    steps:
      - uses: actions/create-github-app-token@f8d387b68d61c58ab83c6c016672934102569859
        id: app-token
        with:
          app-id: ${{ vars.PLATFORM_TOKEN_APP_ID }}
          private-key: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}

  sync-workflows:
    name: Sync Workflow Files
    needs: get-token
    uses: navikt/crm-workflows-base/.github/workflows/workflow-sync.yml@<sha/version>
    permissions:
      contents: write
      pull-requests: write
    secrets:
      TOKEN: ${{ needs.get-token.outputs.token }}
```
