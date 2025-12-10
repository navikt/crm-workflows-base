# Package Promotion

This workflow promotes a package so that it can be deployed in Production. It also commits the new version number to `sfdx-project.json` and set the matching release to latest.

## Jobs

- **Install in PREPROD**
- **Install package in UAT**
- **Promote Package** (needs: Install in PREPROD)
  - Checkout source code
  - Install SF
  - Authorize Dev Hub
  - Get Package Version Info (fails if validation of package version is skipped)
  - Promote package
- **Push new version number to default branch** (needs: Promote Package)
  - Checkout source code
  - Update version number in `sfdx-project.json`
  - Build commit message
  - Commit and Push changes
- **Set package version to released** (needs: Promote Package)
  - Mark matching GitHub release as non-prerelease and latest

Find the release matching the package version, set it to released and mark as latest.

## Secrets

- `secrets.COMMIT_TOKEN` Token used to commit changes.
- `secrets.PROD_AUTH_URL` Required to authenticate towards production.
- `secrets.PREPROD_AUTH_URL` Required to authenticate towards preprod sandbox.
- `secrets.UAT_AUTH_URL` Required to authenticate towards uat sandbox.
- `secrets.PACKAGE_KEY` Needed to install packages with keys (not required)

## Permissions

`contents: write` Is needed in order to check out the repo and commit package version updates.

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/packagePromotion.yml@main
with:
  # Package version ID
  # Required: true
  # Type: string
  package-version-id: ""
secrets:
  COMMIT_TOKEN: my_token
  PACKAGE_KEY: package_key
  PROD_AUTH_URL: prod_auth_url
  PREPROD_AUTH_URL: preprod_auth_url
  UAT_AUTH_URL: uat_auth_url
```

## Full example

```yml
name: "Promote Package Version"
on:
  workflow_dispatch:
    inputs:
      package-version-id:
        description: "Package version ID"
        required: true

permissions: {}
concurrency:
  group: ${{ github.workflow }}-${{inputs.package-version-id}}
  cancel-in-progress: false
jobs:
  create-token:
    runs-on: ubuntu-latest
    permissions: {}
    outputs:
      app-token: ${{ steps.app-token.outputs.token }}
    steps:
      - uses: actions/create-github-app-token@v2
        id: app-token
        with:
          app-id: ${{ var.APP_ID }}
          private-key: ${{ secrets.PRIVATE_KEY }}

  run-package-promotion:
    name: Promote Package
    uses: navikt/crm-workflows-base/.github/workflows/packagePromotion.yml@main
    with:
      package-version-id: 04txxxxxxxxx
    permissions:
      contents: write # Need to update release and commit new package version
    secrets:
      COMMIT_TOKEN: ${{ needs.create-token.outputs.app-token }}
      PROD_AUTH_URL: ${{ secrets.CRM_PROD_SFDX_URL }}
      PREPROD_AUTH_URL: ${{ secrets.CRM_PREPROD_SFDX_URL }}
      UAT_AUTH_URL: ${{ secrets.CRM_UAT_SFDX_URL }}
      PACKAGE_KEY: ${{ secrets.CRM_PACKAGE_KEY }}
```
