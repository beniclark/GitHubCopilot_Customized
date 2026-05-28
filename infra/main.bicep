targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used to generate resource names)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Object ID of the principal (user or service principal) running the deployment, used for Key Vault access')
param principalId string = ''

// ── Naming ────────────────────────────────────────────────────────────────────
var tags = {
  'azd-env-name': environmentName
  environment: 'dev'
}
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// ── Resource Group ─────────────────────────────────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// ── Monitoring: Log Analytics + Application Insights ──────────────────────────
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    logAnalyticsName: 'log-${resourceToken}'
    appInsightsName: 'appi-${resourceToken}'
    location: location
    tags: tags
  }
}

// ── Container Registry ────────────────────────────────────────────────────────
module registry './modules/registry.bicep' = {
  name: 'registry'
  scope: rg
  params: {
    // ACR names are alphanumeric only, 5–50 characters
    name: 'cr${resourceToken}'
    location: location
    tags: tags
  }
}

// ── Storage Account (required by AI Foundry Hub) ──────────────────────────────
module storage './modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    // Storage names are lowercase alphanumeric, 3–24 characters
    name: 'st${resourceToken}'
    location: location
    tags: tags
  }
}

// ── Key Vault (required by AI Foundry Hub) ────────────────────────────────────
module keyVault './modules/keyvault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    name: 'kv-${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// ── App Service Plan + Linux App Service (Docker / ACR) ───────────────────────
module appService './modules/appservice.bicep' = {
  name: 'appservice'
  scope: rg
  params: {
    name: 'app-${resourceToken}'
    planName: 'asp-${resourceToken}'
    location: location
    tags: tags
    containerRegistryLoginServer: registry.outputs.loginServer
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
  }
}

// ── RBAC: AcrPull for the App Service system-assigned managed identity ─────────
module acrPullRole './modules/roleAssignments.bicep' = {
  name: 'acrPullRole'
  scope: rg
  params: {
    containerRegistryName: registry.outputs.name
    principalId: appService.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ── Azure AI Foundry (AI Services, Hub, Project, Model Deployments) ────────────
module ai './modules/ai.bicep' = {
  name: 'ai'
  scope: rg
  params: {
    aiServicesName: 'ais-${resourceToken}'
    aiHubName: 'aih-${resourceToken}'
    aiProjectName: 'aip-${resourceToken}'
    location: location
    tags: tags
    storageAccountId: storage.outputs.id
    keyVaultId: keyVault.outputs.id
    containerRegistryId: registry.outputs.id
    appInsightsId: monitoring.outputs.appInsightsId
  }
}

// ── Outputs (consumed by AZD and app configuration) ───────────────────────────
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.name
output SERVICE_WEB_NAME string = appService.outputs.name
output SERVICE_WEB_URI string = appService.outputs.uri
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.appInsightsConnectionString
output AZURE_AI_SERVICES_ENDPOINT string = ai.outputs.aiServicesEndpoint
output AZURE_AI_PROJECT_NAME string = ai.outputs.aiProjectName
