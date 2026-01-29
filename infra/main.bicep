targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// @description('Id of the user or app to assign application roles')
// param principalId string = ''

// Optional parameters for customization
@description('Name of the container registry')
param containerRegistryName string = ''

@description('Name of the container group')
param containerGroupName string = ''

@description('DNS name label for the container group')
param dnsNameLabel string = ''

@description('CPU cores for the container')
param containerCpu int = 1

@description('Memory in GB for the container')
param containerMemory int = 2

// Environment variables for clawdbot
// Note: At least one AI provider API key is required for clawdbot to function
// Empty values will be passed as empty environment variables - ensure clawdbot can handle this
@secure()
@description('OpenAI API Key (optional)')
param openAiApiKey string = ''

@secure()
@description('Anthropic API Key (optional)')
param anthropicApiKey string = ''

@secure()
@description('Clawdbot Gateway Token')
param clawdbotGatewayToken string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Container registry
module containerRegistry './core/host/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
  }
}

// Log Analytics workspace for monitoring
module logAnalytics './core/monitor/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: rg
  params: {
    name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

// Container Instance
module containerInstance './core/host/container-instance.bicep' = {
  name: 'container-instance'
  scope: rg
  params: {
    name: !empty(containerGroupName) ? containerGroupName : '${abbrs.containerInstanceContainerGroups}${resourceToken}'
    location: location
    tags: tags
    containerRegistryName: containerRegistry.outputs.name
    containerImage: 'clawdbot:latest'
    dnsNameLabel: !empty(dnsNameLabel) ? dnsNameLabel : 'clawdbot-${resourceToken}'
    cpu: containerCpu
    memoryInGb: containerMemory
    port: 18789
    environmentVariables: [
      {
        name: 'OPENAI_API_KEY'
        secureValue: openAiApiKey
      }
      {
        name: 'ANTHROPIC_API_KEY'
        secureValue: anthropicApiKey
      }
      {
        name: 'CLAWDBOT_GATEWAY_TOKEN'
        secureValue: clawdbotGatewayToken
      }
    ]
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    logAnalyticsWorkspaceKey: logAnalytics.outputs.primarySharedKey
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output CLAWDBOT_URL string = containerInstance.outputs.fqdn
output CLAWDBOT_IP string = containerInstance.outputs.ipAddress
