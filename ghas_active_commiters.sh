gh auth login

gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \  
  /orgs/returngis/settings/billing/advanced-security

gh auth refresh -h github.com -s admin:enterprise

gh auth refresh -h github.com -s manage_billing:enterprise

ENTERPRISE_NAME=<YOUR_ENTERPRISE_NAME>

gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /enterprises/$ENTERPRISE_NAME/settings/billing/advanced-security