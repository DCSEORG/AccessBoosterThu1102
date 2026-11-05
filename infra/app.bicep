@description('Azure region for all resources')
param location string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the App Service')
param appServiceName string

@description('Name of the Azure SQL logical server')
param sqlServerName string

@description('Name of the Azure SQL database')
param sqlDatabaseName string

@secure()
param sqlAdminPassword string = 'ChangeThisPassword-123!'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'app'
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v10.0'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'accessadmin'
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${sqlServer.name}/${sqlDatabaseName}'
  location: location
  sku: { name: 'Basic', tier: 'Basic' }
}

output appServicePlanName string = appServicePlan.name
output appServiceName string = appService.name
output appServiceDefaultHostName string = appService.properties.defaultHostName
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
