# Workflows Base

This repo contains reusable workflows for Salesforce development in NAV and is maintained by Team Platforce.

## Short Guide

It is highly recommended to check out the GitHub docs on [reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) before starting to reuse these workflows.
If your repository is not a part of [navikt](https://github.com/navikt) you also need to create the org secrets listed under secrets as repository secrets in your repository.

1. Create a workflow in your repository
2. Reference the workflows used here

## Workflow secrets

Org secrets are maintained by Team Platforce

**List of org secrets:**\
CRM_PROD_SFDX_URL\
CRM_PREPROD_SFDX_URL\
CRM_UAT_SFDX_URL\
CRM_SIT_SFDX_URL\
CRM_DEPLOYMENT_PAT\
CRM_PACKAGE_KEY

### Running workflows toward dev sandboxes

Dev sandboxes are owned and maintained by the individual teams. For use with the Platforce maintained workflows create a Repository Secret with the name DEV_SFDX_URL and the auth url belonging to a sandbox user with enough permissions for deploying.

## Requests

Questions related to the code or project can be made as an issue.

### For NAV-employees

Internal requests can be made via Slack in #Platforce.
