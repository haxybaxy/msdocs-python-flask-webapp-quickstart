param location string
param name string
@secure()
param registryName string
param objectId string
param ServicePrincipalId string

// Reference an existing container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: registryName
  scope: resourceGroup()
}

// Create a new Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: name
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
          certificates: [
            'get'
            'list'
            'create'
            'delete'
          ]
          keys: [
            'get'
            'list'
            'create'
            'delete'
          ]
        }
      }
    ]
    enableRbacAuthorization: true
  }
}

// Store the registry admin password in Key Vault
resource registryPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'registry-password'
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value // Fetches the registry password dynamically
  }
}

// Store the registry admin username in Key Vault
resource registryUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'registry-username'
  properties: {
    value: containerRegistry.name
  }
}

// Add role assignment for GitHub Actions
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, ServicePrincipalId, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User role
    principalId: ServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Output only the Key Vault URI (non-sensitive information)
output keyVaultUri string = keyVault.properties.vaultUri
