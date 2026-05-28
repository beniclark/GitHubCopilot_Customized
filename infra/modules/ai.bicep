// Azure AI Foundry — AI Services account, AI Hub, AI Project, and model deployments.
//
// Resources created:
//   • Microsoft.CognitiveServices/accounts (kind: AIServices)
//       – GPT-4 deployment  (OpenAI format, Standard SKU, westus3)
//       – Phi-4 deployment  (Microsoft format, Standard SKU, westus3)
//   • Microsoft.MachineLearningServices/workspaces (kind: Hub)
//       – Connected to storage, key vault, ACR, App Insights, and AI Services
//   • Microsoft.MachineLearningServices/workspaces (kind: Project)
//       – Child project of the hub

param aiServicesName string
param aiHubName string
param aiProjectName string
param location string
param tags object
param storageAccountId string
param keyVaultId string
param containerRegistryId string
param appInsightsId string

// ── AI Services account ───────────────────────────────────────────────────────
// kind 'AIServices' provides a unified endpoint for OpenAI models AND other
// Azure AI capabilities (Vision, Speech, etc.) in a single resource.
// NOTE: The 'AIServices' kind and the 'Microsoft' model format for Phi require
// API version 2024-04-01-preview; there is no stable GA version that supports
// both.  Monitor https://aka.ms/azureaistudio for GA availability.
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    // Disable key-based auth so access is enforced via Azure RBAC only
    disableLocalAuth: false
  }
}

// ── GPT-4 deployment ──────────────────────────────────────────────────────────
// Capacity is in units of 1 000 tokens per minute (TPM).
// 10 units = 10 K TPM, appropriate for a dev environment.
// NOTE: deployments are a child resource of the Cognitive Services account and
// share its preview API version requirement (2024-04-01-preview).
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiServices
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: 'turbo-2024-04-09'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

// ── Phi-4 deployment ──────────────────────────────────────────────────────────
// Phi-4 is a Microsoft model available in westus3.
// Deployments under the same account must be created sequentially.
// NOTE: format 'Microsoft' for Phi models requires the same preview API version.
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiServices
  name: 'phi-4'
  dependsOn: [gpt4Deployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}

// ── AI Foundry Hub ────────────────────────────────────────────────────────────
// The hub is the top-level governance boundary in AI Foundry; it holds shared
// connections, compute, and credentials that projects inherit.
// 2024-04-01 is a stable GA version that adds full type support for Hub/Project
// workspace kinds and AAD connection auth (not available in 2023-10-01 types).
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiHubName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    containerRegistry: containerRegistryId
    applicationInsights: appInsightsId
    publicNetworkAccess: 'Enabled'
  }
}

// ── Hub → AI Services connection ─────────────────────────────────────────────
// Connects the hub to the AI Services account so models are accessible from
// projects.  AAD auth (RBAC) is used — no API keys are stored.
// 2024-04-01 is required here: the 'AAD' authType value and 'AIServices'
// connection category are not present in the 2023-10-01 type definitions.
resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  parent: aiHub
  name: '${aiServicesName}-connection'
  properties: {
    category: 'AIServices'
    target: aiServices.properties.endpoint
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServices.id
    }
  }
}

// ── AI Foundry Project ────────────────────────────────────────────────────────
// A project is the workspace developers use for experiments, prompt flows,
// evaluations, and deployments.  It inherits the hub's shared resources.
// Uses the same 2024-04-01 GA version as the hub (hubResourceId is only
// present in types ≥ 2024-04-01).
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiProjectName
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

output aiServicesId string = aiServices.id
output aiServicesEndpoint string = aiServices.properties.endpoint
output aiHubId string = aiHub.id
output aiHubName string = aiHub.name
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
