// Linux App Service Plan + App Service configured for Docker / ACR.
//
// Key design decisions:
//   • kind = 'app,linux,container'  — Linux container host
//   • System-assigned managed identity is enabled on the App Service
//   • acrUseManagedIdentityCreds = true  — pulls images via RBAC, no passwords
//   • The AcrPull role assignment is in roleAssignments.bicep (needs the
//     principal ID output from this module)

param name string
param planName string
param location string
param tags object
param containerRegistryLoginServer string
param appInsightsConnectionString string
param appInsightsInstrumentationKey string

@description('App Service Plan SKU.  B1 is the minimum tier that supports Linux containers.')
param sku string = 'B1'

// ── App Service Plan ──────────────────────────────────────────────────────────
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: sku
  }
  properties: {
    reserved: true // required for Linux
  }
}

// ── App Service ───────────────────────────────────────────────────────────────
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  // 'azd-service-name' tag tells AZD which service to deploy here
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      // Placeholder image — AZD / CI will overwrite this on first deploy.
      // The image path follows the convention: <registry>/<azd-service-name>:latest
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/web:latest'
      // Use the system-assigned identity to authenticate against ACR (no passwords)
      acrUseManagedIdentityCreds: true
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'WEBSITES_PORT'
          value: '3000'
        }
      ]
    }
  }
}

output id string = appService.id
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.principalId
