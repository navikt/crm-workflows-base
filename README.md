# crm-platform-workflows
All workflows used for all SFDX projects.

# Secrets needed

## SFDX Auth URL

Use the following command to get a SFDX Auth URL:
```bash
sfdx force:org:display -u [LOGIN_TO_ORG] --verbose
```

- PROD_SFDX_URL **[REQUIRED]**
  - SFDX Auth Url for the prod env (ask [@magnushamrin](https://github.com/magnushamrin))
- PREPROD_SFDX_URL **[REQUIRED]**
  - SFDX Auth Url for the preprod Sandbox (ask [@magnushamrin](https://github.com/magnushamrin))
- INTEGRATION_SANDBOX_SFDX_URL **[REQUIRED]**
  - SFDX Auth Url for the Integration Sandbox (ask [@magnushamrin](https://github.com/magnushamrin))
- DEV_SFDX_URL **[OPTIONAL]**
  - SFDX Auth Url for the your own dev Sandbox (create your own)

## Parameters

- DEPLOY_TO_DEV_AFTER_PACKAGE_CREATION **[OPTIONAL]**
  - Set to '1' if you want to auto-deploy to DEV_SFDX_URL after package creation
  - Set to '0' to NOT install the package anywhere

## Other

- PACKAGE_KEY **[REQUIRED]**
  - The password for packages in NAV CRM
- DEPLOYMENT_PAT **[REQUIRED]**
  - The administrator of the repo needs to [create a PAT](https://docs.github.com/en/enterprise/2.17/user/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with "REPO" access
- SLACK_WEBHOOK **[OPTIONAL]**
  - If you want to post logins to a functional scratch orgs after a PR has been created, create a [Slack Webhook](https://slack.com/intl/en-no/help/articles/115005265063-Incoming-Webhooks-for-Slack)

# Installing
Copy the [workflows](workflows) folder to .github/workflows in your repo.
