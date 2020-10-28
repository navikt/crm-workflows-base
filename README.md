All workflows used for all SFDX projects in NAV.

# Installing
Copy the [workflows](workflows) folder to .github/workflows in your repo.

# Secrets

## Required Environment Secrets

SFDX Auth Url for production, pre-production and integration sandbox. Ask [@magnushamrin](https://github.com/magnushamrin) for assistance, by giving him admin access to your repo to add these auth URL secrets.

- PROD_SFDX_URL ```[REQUIRED]```
- PREPROD_SFDX_URL ```[REQUIRED]```
- INTEGRATION_SANDBOX_SFDX_URL ```[REQUIRED]```

## Optional Environment Secrets

SFDX Auth Url for development and UAT sandboxes. These sandboxes must be unique for each team or repo. [Create your own SFDX Auth Url](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_view_info.htm) to add them as secrets here (also look at the bottom of this readme for the command).

- UAT_SANDBOX_SFDX_URL ```[OPTIONAL]```
- DEV_SFDX_URL ```[OPTIONAL]```

## Parameters

- DEPLOY_TO_DEV_AFTER_PACKAGE_CREATION ```[OPTIONAL]```
- DEPLOY_TO_UAT_AFTER_PACKAGE_CREATION ```[OPTIONAL]```

**Valid values are the following**

```java
1 // auto-deploy to the respective sandbox
0 // will NOT auto-deploy
null // will NOT auto-deploy if the secret is not set
```

## Other

- PACKAGE_KEY ```[REQUIRED]```
  - The password for packages in NAV CRM
- DEPLOYMENT_PAT ```[REQUIRED]```
  - The administrator of the repo needs to [create a PAT](https://docs.github.com/en/enterprise/2.17/user/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with "REPO" access

# SFDX Auth URL

Use the following command to get a SFDX Auth URL:
```bash
sfdx force:org:display -u [ORG_ALIAS] --verbose
```