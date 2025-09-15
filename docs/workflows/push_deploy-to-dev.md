# [PUSH] Deploy to Dev

|               |                       |
| ------------- | --------------------- |
| **Initiator** | Pushing to Dev branch |
| **Type**      | Source Deploy         |

## Intro

This workflows automatically runs whenever someone pushes or merges a PR into the `dev` branch. It's a simple `sfdx force:source:deploy`, so no packages. However, dependant packages are installed to make sure the metadata will deploy.

## Secrets

- Environment secrets
  - `secrets.CRM_PROD_SFDX_URL`
  - `secrets.CRM_DEV_SFDX_URL`
  - `secrets.CRM_PACKAGE_KEY`
    - Needed to install dependant packages.

## Example usage

```yml
name: "[PUSH] Deploy to Dev"
on:
  workflow_dispatch:
  push:
    branches:
      - dev
    paths:
      - "force-app/**"
jobs:
  deploy-metadata:
    name: Create new package
    runs-on: ubuntu-latest
    steps:
      # Checkout source code
      - name: Checkout source code
        uses: actions/checkout@v2

      # Install SFDX
      - name: Install SF CLI
        uses: navikt/sf-gha-install-sf-cli@3f1abbc990b03fb544e80169920fea2e94946d1a

      # Authenticate prod
      - name: Authenticate prod
        uses: navikt/sf-gha-authenticateOrg@da2f995ee865e05111574719abfc5ba12b459f0c
        with:
          auth-url: ${{ secrets.CRM_PROD_SFDX_URL }}
          alias: prod
          setDefaultUsername: false
          setDefaultDevhubUsername: true

      # Authenticate dev sandbox
      - name: Authenticate dev sandbox
        uses: navikt/sf-gha-authenticateOrg@da2f995ee865e05111574719abfc5ba12b459f0c
        with:
          auth-url: ${{ secrets.DEV_SFDX_URL }}
          alias: dev
          setDefaultUsername: true
          setDefaultDevhubUsername: false

      # Install sfpowerkit plugin used to install multiple packages only by version number
      - name: Install sfpowerkit plugin
        run: echo y | sfdx plugins:install sfpowerkit@2.0.1

      # Get package keys
      - name: Get package keys
        id: install-keys
        run: |
          keys=""
          for p in $(jq '.result | .[].Name' -r <<< "$(sfdx force:package:list --json)"); do
              keys+=$p":${{ secrets.CRM_PACKAGE_KEY }} "
          done

          echo "name=keys$(echo $keys)" >> GITHUB_OUTPUT

      # Install packages this repo is dependant on
      - name: Install dependant packages
        run: sfdx sfpowerkit:package:dependencies:install -u dev -r -a -w 60 -k '${{ steps.install-keys.outputs.keys }}'

      # Install new package version into dev sandbox
      - name: Install new package version into dev sandbox
        if: success()
        id: dev-installation
        run: |
          sfdx force:source:deploy -p force-app -u dev -l RunLocalTests
```
