// AcrPull role assignment for the App Service system-assigned managed identity.
// This lets the App Service pull container images from ACR without storing
// any registry credentials as app settings.

param containerRegistryName string

@description('Object ID of the principal (the App Service managed identity) to assign AcrPull to')
param principalId string

@allowed(['ServicePrincipal', 'User', 'Group'])
param principalType string = 'ServicePrincipal'

// AcrPull built-in role: 7f951dda-4ed3-4680-a7ca-43fe172d538d
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, principalId, acrPullRoleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}
