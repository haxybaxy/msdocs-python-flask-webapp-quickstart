@sys.description('The user alias to add to the deployment name')
param userAlias string = 'zalsaheb'
@sys.description('The App Service Plan name')
@minLength(3)
@maxLength(24)
param appServicePlanName string
@sys.description('The API App name (backend)')
@minLength(3)
@maxLength(24)
param appServiceAppName string
@sys.description('The Azure location where the resources will be deployed')
param location string = resourceGroup().location
@secure()
param keyVaultName string
param containerRegistryName string
param ServicePrincipalId string

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    name: containerRegistryName
    sku: 'Standard'
    ServicePrincipalId: ServicePrincipalId
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    location: location
    name: keyVaultName
    registryName: containerRegistryName
    objectId: subscription().subscriptionId
    ServicePrincipalId: ServicePrincipalId
  }
  dependsOn: [
    containerRegistry
  ]
}


module appService 'modules/app-service.bicep' = {
  name: 'appService-${userAlias}'
  params: {
    location: location
    appServiceAppName: appServiceAppName
    appServicePlanName: appServicePlanName
    containerRegistryName: containerRegistryName
  }
  dependsOn: [
    keyVault
  ]
}

output appServiceAppHostName string = appService.outputs.appServiceAppHostName
