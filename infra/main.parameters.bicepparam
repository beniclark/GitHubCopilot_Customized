using './main.bicep'

// The environment name drives all resource names.  Set AZURE_ENV_NAME before
// running `azd up`, or override here for a fixed dev environment name.
param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'zavastorefrontdev')

// westus3 is required: GPT-4 and Phi-4 are available in that region.
param location = readEnvironmentVariable('AZURE_LOCATION', 'westus3')

// Your Azure AD object ID — needed so AZD can grant Key Vault access during
// provisioning.  Populated automatically by `azd up`.
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
