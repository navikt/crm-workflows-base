# Create Package Version

This workflow creates a new package version and a GitHub pre-release.

The workflow uses `sfp cli` and `jq`.

## Jobs

### Create Package Version

Create the package version

#### Steps

##### Checkout source code

Checkout source code

##### Install SF

Install `sf cli` using the action `navikt/sf-gha-install-sf-cli`

##### Authorize Dev Hub

Autorize the dev hub so that we can create the package

##### Delete unpackagable and scratch-org folder

Delete the following folders if present in as they should not be a part of the package

- force-app/unpackagable
- force-app/unpackagable-with-auto-deploy
- force-app/scratch-org

##### Create package version

Create the package version using `sf cli`.

If the branch is not the default branch (typically `main`), it will use the `--branch` flag of `sf package version create`

If `create-alpha-package` is `true` add the `--skip-validation`, if not use `--code-coverage`

If `installation-key-bypass` is `true` add the `--installation-key-bypass` flag, if not set `--installation-key` with the secret `PACKAGE_KEY`

### Install in SIT Sandbox

Install the new package version and deploy the metadata in the SIT sandbox.

### Create release

#### Checkout source code

Check out the full repository and all history/tags

#### Set release variables

Calculate release variables that are used in the next step

#### Create Release

Create a GitHub release using the action [`gh-release`](https://github.com/marketplace/actions/gh-release)

## Secrets

- `secrets.DEV_HUB_AUTH_URL` Needed to authenticate with the dev hub
- `secrets.SIT_AUTH_URL` Needed to authenticate with the sit sandbox
- `secrets.PACKAGE_KEY` Needed if the package should have a package key

## Usage

```yml
uses: navikt/crm-workflows-base/.github/workflows/createPackageVersion.yml@main
  with:
    # Whether to create an alpha package (skip validation)
    # required: false
    # type: boolean
    # default: false
    create-alpha-package:

    # Whether to bypass the installation key for the package
    # required: false
    # type: boolean
    # default: false
    installation-key-bypass: false

    # Path to scratch org definition file
    # required: false
    # type: string
    # default: config/project-scratch-def.json
    scratch-org-def-file: 'config/project-scratch-def.json'

    # Path to metadata to deploy after package installation
    # Required: false
    # Type: string
    metadata-path: ''

    # Wait time for package creation (minutes)
    # Required: false
    # Type: number
    # default: 120
    wait: 120
```

## Full Example

```yml
name: "Create Package Version"
on:
  push:
    branches:
      - "main"
permissions: {}
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
jobs:
  run-pr-validation:
    name: Create package Version
    uses: navikt/crm-workflows-base/.github/workflows/createPackageVersion.yml@main
    permissions:
      contents: write
    secrets:
      PACKAGE_KEY: ${{ secrets.PACKAGE_KEY }}
      DEV_HUB_AUTH_URL: ${{ secrets.CRM_PROD_SFDX_URL }}
      SIT_AUTH_URL: ${{ secrets.CRM_SIT_SFDX_URL }}
```
