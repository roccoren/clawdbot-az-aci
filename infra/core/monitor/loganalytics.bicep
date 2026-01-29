param name string
param location string = resourceGroup().location
param tags object = {}

@description('Number of days to retain data')
param retentionInDays int = 30

@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
param sku string = 'PerGB2018'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
  }
}

output id string = logAnalytics.id
output name string = logAnalytics.name
output primarySharedKey string = logAnalytics.listKeys().primarySharedKey
