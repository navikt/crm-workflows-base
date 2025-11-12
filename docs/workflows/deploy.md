# Deploy

This workflow deploys either a package, metadata or both based on the input, to a specified org.

## Steps

### Set SF Auth URL

Get auth URL based on org name. Also possible to supply directly with an org name.

### Install SF

Install SF CLI sing the action `sf-gha-install-sf-cli`

### Authorize SF

Authenticate with the target org where we are deploying the package/metadata

### Install pacage in target org

If a package id is suplied, try to intall the package in the target org.

### Checkout source code

Check out the source code for the package

### Deploy metadata

If metadata-path is supplied, deploy the metadata in the target org.

## Secrets

- `secrets.CRM_PROD_SFDX_URL` Required to authenticate towards production.
- `secrets.CRM_PREPROD_SFDX_URL` Required to authenticate towards preprod sandbox.
- `secrets.DEV_SFDX_URL` Required to authenticate towards dev sandbox.
- `secrets.CRM_UAT_SFDX_URL` Required to authenticate towards crm-uat sandbox.
- `secrets.UAT_SFDX_URL` Required to authenticate towards uat sandbox.
- `secrets.CRM_SIT_SFDX_URL` Required to authenticate towards sit sandbox.
- `secrets.CRM_PACKAGE_KEY` Needed to install packages with keys

## Permissions

`contents: read` Is needed in order to checkout and read the metadata to deploy.

## Usage

Note that you must supply either `package-id` or `metadata-path` or both.

```yml
uses: navikt/crm-workflows-base/.github/workflows/deploy.yml@main
  with:
    # Org name (prod, preprod, dev, uat, sit)
    # Required: true
    # Type: string
    org: 'prod'

    # Package ID
    # Required: false
    # Type: string
    package-id: '04t...'

    # Path to metadata folder
    # Required: false
    # Type: string
    metadata-path: 'force-app/unpackagble-with-autodeploy'

    # Wait time for package install (minutes)
    # Required: false
    # Type: number
    # Default: 10
    install-wait: 10

    # Publish wait time (minutes)
    # Required: false
    # Type: number
    # Default: 10
    publish-wait: 10
```

## Full example

```yml
name: "Deploy to SIT"
on:
  workflow_dispatch:

permissions: {}
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
jobs:
  deploy:
    name: Deploy
    uses: navikt/crm-workflows-base/.github/workflows/deploy.yml@main
    with:
      org: sit
      package-id: 04txxxxxxxxx
      metadata-path: force-app/unpackaged
    permissions:
      contents: read
    secrets:
      PACKAGE_KEY: ${{ secrets.PACKAGE_KEY }}
      CRM_PROD_SFDX_URL: ${{ secrets.CRM_PROD_SFDX_URL }}
      CRM_PREPROD_SFDX_URL: ${{ secrets.CRM_PREPROD_SFDX_URL }}
      DEV_SFDX_URL: ${{ secrets.DEV_SFDX_URL }}
      CRM_UAT_SFDX_URL: ${{ secrets.CRM_UAT_SFDX_URL }}
      UAT_SFDX_URL: ${{ secrets.UAT_SFDX_URL }}
      CRM_SIT_SFDX_URL: ${{ secrets.CRM_SIT_SFDX_URL }}
      CRM_PACKAGE_KEY: ${{ secrets.CRM_PACKAGE_KEY }}
```
