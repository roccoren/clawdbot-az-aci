param name string
param location string = resourceGroup().location
param tags object = {}

@description('Container image to deploy')
param containerImage string

@description('Container image is provided as a fully qualified reference')
param imageIsFullPath bool = false

@description('Container registry name')
param containerRegistryName string

@description('DNS name label for the container group')
param dnsNameLabel string

@description('CPU cores')
param cpu int = 1

@description('Memory in GB')
param memoryInGb int = 2

@description('Port to expose')
param port int = 80

@description('Environment variables for the container')
param environmentVariables array = []

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Log Analytics workspace key')
@secure()
param logAnalyticsWorkspaceKey string

// Get reference to container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    containers: [
      {
        name: 'clawdbot'
        properties: {
          image: imageIsFullPath ? containerImage : '${containerRegistry.properties.loginServer}/${containerImage}'
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          environmentVariables: environmentVariables
          resources: {
            requests: {
              cpu: cpu
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: dnsNameLabel
    }
    imageRegistryCredentials: imageIsFullPath ? [] : [
      {
        server: containerRegistry.properties.loginServer
        username: containerRegistry.listCredentials().username
        password: containerRegistry.listCredentials().passwords[0].value
      }
    ]
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalyticsWorkspaceId
        workspaceKey: logAnalyticsWorkspaceKey
      }
    }
  }
}

output id string = containerGroup.id
output name string = containerGroup.name
output fqdn string = 'http://${containerGroup.properties.ipAddress.fqdn}:${port}'
output ipAddress string = containerGroup.properties.ipAddress.ip
