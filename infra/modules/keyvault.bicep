// Key Vault — required by the AI Foundry Hub for secret storage.
// RBAC authorization is enabled; no legacy access policies are used.

param name string
param location string
param tags object

@description('Object ID of the principal that should receive Key Vault Administrator access (typically the deploying user)')
param principalId string = ''

var keyVaultAdministratorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator
)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
}

// Grant the deploying user Key Vault Administrator so they can manage secrets
// during and after provisioning.
resource deployerAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(keyVault.id, principalId, keyVaultAdministratorRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultAdministratorRoleId
    principalId: principalId
    principalType: 'User'
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
