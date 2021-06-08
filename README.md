All workflows used for all SFDX projects in NAV.

# Installing

Copy the [workflows](workflows) folder to .github/workflows in your repo.

# Secrets

## Required Environment Secrets

SFDX Auth Url for production, pre-production and integration sandbox. Ask [@frodehoen](https://github.com/frodehoen) for assistance, by giving him admin access to your repo to add these auth URL secrets.

- PROD_SFDX_URL `[REQUIRED]`
- PREPROD_SFDX_URL `[REQUIRED]`
- INTEGRATION_SANDBOX_SFDX_URL `[REQUIRED]`

## Other Required Secrets

- PACKAGE_KEY `[REQUIRED]`
  - The password for packages in NAV CRM
- DEPLOYMENT_PAT `[REQUIRED]`
  - The administrator of the repo needs to [create a PAT](https://docs.github.com/en/enterprise/2.17/user/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with "REPO" access

## Deployment to dev and UAT sandboxes

SFDX Auth Url for dev and UAT sandboxes, which can be manually or automatically deployed when creating new packages. These sandboxes should be unique for each team or repo. See how to create [SFDX Auth URL](#SFDX-Auth-URL) below.

- UAT_SFDX_URL `[OPTIONAL]`
- DEV_SFDX_URL `[OPTIONAL]`
- DEPLOY_TO_DEV_AFTER_PACKAGE_CREATION `[OPTIONAL, VALID VALUES ARE 1 OR 0]`
- DEPLOY_TO_UAT_AFTER_PACKAGE_CREATION `[OPTIONAL, VALID VALUES ARE 1 OR 0]`

```java
1 // auto-deploy to the respective sandbox
0 // will NOT auto-deploy
null // will NOT auto-deploy if the secret is not set
```

# SFDX Auth URL

Use the following command to get a SFDX Auth URL (see value for `Sfdx Auth Url`):

```bash
sfdx force:org:display -u [ORG_ALIAS] --verbose
```

Source: [Create your own SFDX Auth Url](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_view_info.htm)
