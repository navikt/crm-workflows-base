# Update mise Tools

This reusable workflow checks the tools declared in `mise.toml` for updates. When updates are available, it runs `mise upgrade` and creates or updates a pull request with the changed `mise.toml` and optional `mise.lock`.

## Steps

### Validate Branches

Validates the base and update branch names and ensures they differ.

### Prepare Update Branch

Checks out the configured base branch and prepares the update branch:

- An open pull request must have an existing update branch.
- The local update branch is recreated from the latest base branch.
- The current remote update branch commit is recorded for concurrency protection.

### Upgrade Tools

Runs `mise upgrade --dry-run-code` to check for updates. When updates are available, runs `mise upgrade` to update `mise.toml` and, when enabled, `mise.lock`.

### Commit and Create Pull Request

Resets an existing remote update branch to the latest base branch with an exact force-with-lease, or creates the branch when it is missing. It then uses GitHub's GraphQL API to create a signed commit containing the changed configuration files directly on the remote branch.

The workflow creates a pull request when none exists. An existing pull request is updated by replacing its generated update commit.

## Inputs

- `base-branch` Optional. Base branch for the pull request. Default: `main`.
- `branch` Optional. Branch for the update pull request. Default: `chore/mise-tools-update`.
- `commit-message` Optional. Commit message for the update. Default: `chore(mise): update tool versions`.
- `title` Optional. Pull request title. Default: `chore(mise): update tool versions`.
- `PLATFORM_TOKEN_APP_ID` Required. GitHub App client ID used to generate the installation token.

## Secrets

- `PLATFORM_TOKEN_APP_PRIVATE_KEY` Required. Private key for the GitHub App used to generate the installation token.

The GitHub App installation must have `contents: write` and `pull-requests: write` access to the target repository.

## Permissions

The calling job must grant these permissions because a reusable workflow cannot elevate the caller token:

- `contents: write`
- `pull-requests: write`

The target repository must also allow GitHub Actions to create pull requests.

## Behavior

- When no updates or configuration file changes are found, no commit, remote branch, or pull request is created.
- When an open update pull request exists, its branch is reset to the latest base branch and receives a new signed update commit.
- A stale update branch without an open pull request is recreated from the latest base branch.
- A missing update branch is created from the latest base branch before the signed commit is added.
- Concurrent branch changes cause the force-with-lease or expected-head check to fail without overwriting remote changes.

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/mise-tools-update.yml@<sha/version>
with:
  # Required: false
  # Type: string
  # Default: main
  base-branch: main

  # Required: false
  # Type: string
  # Default: chore/mise-tools-update
  branch: chore/mise-tools-update

  # Required: false
  # Type: string
  # Default: chore(mise): update tool versions
  commit-message: chore(mise): update tool versions

  # Required: false
  # Type: string
  # Default: chore(mise): update tool versions
  title: chore(mise): update tool versions
  # Required: true
  # Type: string
  # GitHub App client ID
  PLATFORM_TOKEN_APP_ID: ${{ vars.PLATFORM_TOKEN_APP_ID }}
secrets:
  PLATFORM_TOKEN_APP_PRIVATE_KEY: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}
```

## Full Example

```yml
name: Update mise Tools

on:
  schedule:
    - cron: "30 8,12 * * 1-5"
  workflow_dispatch:

permissions: {}

concurrency:
  group: mise-tools-update-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false

jobs:
  update-mise-tools:
    uses: navikt/crm-workflows-base/.github/workflows/mise-tools-update.yml@<sha/version>
    with:
      PLATFORM_TOKEN_APP_ID: ${{ vars.PLATFORM_TOKEN_APP_ID }}
    permissions:
      contents: write
      pull-requests: write
    secrets:
      PLATFORM_TOKEN_APP_PRIVATE_KEY: ${{ secrets.PLATFORM_TOKEN_APP_PRIVATE_KEY }}
```
