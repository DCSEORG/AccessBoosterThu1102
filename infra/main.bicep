targetScope = 'subscription'

@description('Timestamp suffix used to make resource names unique')
param timestamp string = utcNow('yyyyMMddHHmmss')

@description('Azure region for all resources')
param location string = 'eastus'

@secure()
@description('SQL administrator password. Replace the placeholder for production.')
param sqlAdminPassword string = 'ChangeThisPassword-123!'

var resourceGroupName = 'rg-access-booster-${timestamp}'
var appServicePlanName = 'asp-access-booster-${timestamp}'
var appServiceName = 'app-access-booster-${timestamp}'
var sqlServerName = 'sql-access-booster-${timestamp}'
var sqlDatabaseName = 'AccessCinema'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module appResources 'app.bicep' = {
  name: 'appResources'
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: appServicePlanName
    appServiceName: appServiceName
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminPassword: sqlAdminPassword
  }
}

output resourceGroupName string = resourceGroup.name
output appServicePlanName string = appResources.outputs.appServicePlanName
output appServiceName string = appResources.outputs.appServiceName
output appServiceDefaultHostName string = appResources.outputs.appServiceDefaultHostName
output sqlServerName string = sqlServerName
output sqlDatabaseName string = sqlDatabaseName
