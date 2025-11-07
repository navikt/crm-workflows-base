# [PR] Validation

This workflow automatically validates that metadata is valid, tests run successfully and that code coverage is at least 85%. The workflows runs on all Pull Requests, regardless of source and destination.

The workflow uses `sfp cli`.

## Steps

### Checkout source code

Fetch all history for all tags and branches

### Delete unpackagable

Delete any folder named unpackagable, unpackagable-with-auto-deploy or scratch-org

### Authenticate dev hub

Authenticate towards the dev hub

### Generate package keys

Check if any package requires an installation key, if yes generate key-value pairs based on `secrets.PACKAGE_KEY` separated by spaces.
Example string: "packageA:pw123 packageB:pw123"

### Validate the metadata

Validate using the command `sfp validate pool`. It fetches a scratch org from the pool `ci`.

#### Available flags

- --keys added if step "Generate package keys" produces a key-pair
- --ref added if `ref` is used
- --baseRef added if `baseRef` is used

### Upload logs

Upload any logs and store them for 7 days.

## Secrets

- `secrets.DEV_HUB_SFDX_URL` Needed to authenticate with the dev hub
- `secrets.PACKAGE_KEY` Needed to install packages with keys

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/validate.yml@main
  with:
    # The version of SFP to use
    # Required: true
    # Default: 39.8.0-17204768834
    sfp-version: ''

    # The git ref to checkout
    # Required: false
    ref: ''

    # The base git ref to compare changes against (used for PRs)
    # Required: false
    base-ref: ''
```

Note that `ref` and `base-ref` must be used together

## Full Example

```yml
name: "[PR] Validate"
on:
  pull_request:
    branches:
      - "*"
permissions: {}
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
jobs:
  run-pr-validation:
    name: Validate PR
    uses: navikt/crm-workflows-base/.github/workflows/validate.yml@main
    with:
      base-ref: ${{ github.event.pull_request.base.sha }}
      ref: ${{ github.event.pull_request.head.sha }}
    permissions:
      contents: read
    secrets:
      PACKAGE_KEY: ${{ secrets.PACKAGE_KEY }}
      DEV_HUB_SFDX_URL: ${{ secrets.CRM_PROD_SFDX_URL }}
```
