# crm-platform-workflows
All workflows used for all SFDX projects.

# Secrets needed

- PROD_SFDX_URL
  - SFDX Auth Url for the prod env (ask [@magnushamrin](https://github.com/magnushamrin))
- PREPROD_SFDX_URL
  - SFDX Auth Url for the preprod Sandbox (ask [@magnushamrin](https://github.com/magnushamrin))
- INTEGRATION_SANDBOX_SFDX_URL
  - SFDX Auth Url for the Integration Sandbox (ask [@magnushamrin](https://github.com/magnushamrin))
- PREPROD_SFDX_URL
  - SFDX Auth Url for the your own dev Sandbox (create your own)
- PACKAGE_KEY
  - The password for packages in NAV CRM
- DEPLOYMENT_PAT
  - The administrator of the repo needs to [create a PAT](https://docs.github.com/en/enterprise/2.17/user/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with "REPO" access
- SLACK_WEBHOOK
  - If you want to post logins to a functional scratch orgs after a PR has been created, create a [Slack Webhook](https://slack.com/intl/en-no/help/articles/115005265063-Incoming-Webhooks-for-Slack)

# Installing
Copy the [workflows](workflows) folder to .github/workflows in your repo.
