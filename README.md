# Clawdbot Azure Container Instance Deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Froccoren%2Fclawdbot-az-aci%2Fmain%2Fazuredeploy.json)

Deploy [Clawdbot](https://github.com/clawdbot/clawdbot) on Azure Container Instances (ACI) using Azure Developer CLI (azd).

## Overview

This repository provides an automated deployment solution for running Clawdbot, an open-source AI assistant, on Azure Container Instances. The deployment includes:

- **Azure Container Instance** - Hosts the Clawdbot container
- **Azure Container Registry** - Stores the Docker image
- **Log Analytics Workspace** - Monitors container logs and metrics
- **Automated deployment scripts** - Simplified deployment using Azure Developer CLI
- **GitHub Actions workflow** - Automated Docker image building and publishing
- **One-click Deploy to Azure** - Deploy directly from the Azure Portal

## Prerequisites

Before deploying, ensure you have:

1. **Azure Subscription** - [Create a free account](https://azure.microsoft.com/free/)
2. **Azure Developer CLI (azd)** - [Install azd](https://aka.ms/azure-dev/install)
3. **Docker** (optional, for local testing) - [Install Docker](https://docs.docker.com/get-docker/)
4. **API Keys** - At least one of:
   - [OpenAI API Key](https://platform.openai.com/api-keys)
   - [Anthropic API Key](https://console.anthropic.com/)

## Quick Start

### Option 1: Deploy to Azure (One-Click)

Click the "Deploy to Azure" button above to deploy Clawdbot directly from the Azure Portal. This will:

1. Open the Azure Portal deployment page
2. Prompt you to enter your API keys (at least one required: OpenAI or Anthropic)
3. Create all necessary Azure resources:
   - Azure Container Instance (running Clawdbot)
   - Azure Container Registry
   - Log Analytics Workspace for monitoring
4. Deploy and start Clawdbot automatically

**Note**: The one-click deployment uses the pre-built Clawdbot image from GitHub Container Registry. A gateway token will be auto-generated for security.

### Option 2: Deploy via Azure Developer CLI

For more control and local development, use the Azure Developer CLI method:

### 1. Clone the Repository

```bash
git clone https://github.com/roccoren/clawdbot-az-aci.git
cd clawdbot-az-aci
```

### 2. Configure Environment

Copy the example environment file and add your API keys:

```bash
cp .env.example .env
```

Edit `.env` and add at least one API key:

```bash
# Required: Add at least one AI provider API key
OPENAI_API_KEY=sk-your-openai-key-here
# OR
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key-here
```

### 3. Deploy to Azure

Run the deployment script:

```bash
./deploy.sh
```

The script will:
1. Check for Azure Developer CLI installation
2. Login to Azure (if needed)
3. Generate a secure gateway token
4. Provision Azure resources
5. Build and deploy the Docker container
6. Display the Clawdbot URL and access token

### 4. Access Clawdbot

After deployment completes:

1. Open the displayed URL in your browser (e.g., `http://clawdbot-xxxxx.eastus.azurecontainer.io:18789`)
2. Paste your gateway token when prompted
3. Start using Clawdbot!

## Manual Deployment

If you prefer to run individual commands:

```bash
# Login to Azure
azd auth login

# Initialize the environment
azd init

# Provision Azure resources
azd provision

# Deploy the container
azd deploy

# View deployment outputs
azd env get-values
```

## Configuration

### Environment Variables

The `.env` file supports the following variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key | One of the API keys |
| `ANTHROPIC_API_KEY` | Anthropic API key | One of the API keys |
| `CLAWDBOT_GATEWAY_TOKEN` | Gateway security token | Auto-generated if not set |
| `AZURE_LOCATION` | Azure region (e.g., eastus) | No (default: eastus) |
| `CONTAINER_CPU` | CPU cores (1-4) | No (default: 1) |
| `CONTAINER_MEMORY` | Memory in GB (1-16) | No (default: 2) |

### Customizing Resources

You can customize the deployment by modifying parameters in `infra/main.bicep` or passing them during provisioning:

```bash
azd provision --set containerCpu=2 --set containerMemory=4
```

## Architecture

The deployment creates the following Azure resources:

```
┌─────────────────────────────────────────┐
│         Resource Group                  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Container Registry (ACR)       │   │
│  │  - Stores Docker images         │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Container Instance (ACI)       │   │
│  │  - Runs Clawdbot                │   │
│  │  - Public IP with DNS           │   │
│  │  - Port 18789 exposed           │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Log Analytics Workspace        │   │
│  │  - Container logs & metrics     │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## Management Commands

### View Logs

```bash
# View container logs in real-time
azd monitor --logs

# Or use Azure CLI
az container logs --resource-group <rg-name> --name <container-name> --follow
```

### Update Deployment

To update the deployment with new code or configuration:

```bash
./deploy.sh
```

Or manually:

```bash
azd deploy
```

### Stop/Start Container

```bash
# Stop the container
az container stop --resource-group <rg-name> --name <container-name>

# Start the container
az container start --resource-group <rg-name> --name <container-name>
```

### Delete All Resources

To remove all Azure resources created by this deployment:

```bash
azd down
```

## Troubleshooting

### Container not starting

1. Check container logs:
   ```bash
   azd monitor --logs
   ```

2. Verify API keys are set correctly in `.env`

3. Check container status:
   ```bash
   az container show --resource-group <rg-name> --name <container-name>
   ```

### Cannot access Clawdbot URL

1. Verify the container is running:
   ```bash
   az container show --resource-group <rg-name> --name <container-name> --query "instanceView.state"
   ```

2. Check network connectivity:
   ```bash
   curl http://<your-clawdbot-url>:18789
   ```

3. Ensure port 18789 is accessible (not blocked by firewall)

### API key errors

Make sure at least one AI provider API key is set:
- OpenAI: `OPENAI_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`

## Costs

Azure Container Instances pricing is based on:
- CPU cores allocated
- Memory allocated
- Runtime duration

Estimated monthly cost (default configuration: 1 CPU, 2GB RAM, 24/7):
- Approximately $30-40 USD/month

To reduce costs:
- Use smaller CPU/memory allocation
- Stop the container when not in use
- Use Azure pricing calculator: https://azure.microsoft.com/pricing/calculator/

## Security

⚠️ **Important Security Considerations**

### Gateway Token

The gateway token is automatically generated and stored in `.env`. Keep this secure as it provides access to your Clawdbot instance.

### API Keys

Never commit `.env` file to version control. API keys are stored as secure parameters in Azure.

### Network Security

**WARNING**: By default, the container is exposed on a public IP address with only the gateway token for protection. This poses security risks.

**Recommended Security Measures**:
1. **IP Allowlisting**: Configure Azure NSG rules to restrict access to known IP addresses
2. **Private Deployment**: Use Azure Virtual Networks (VNet) for private deployment
3. **Web Application Firewall**: Implement Azure Front Door or Application Gateway with WAF
4. **Strong Gateway Token**: Always use a strong, randomly generated gateway token (auto-generated by deploy.sh)
5. **Regular Updates**: Keep Clawdbot and dependencies updated
6. **Monitor Access**: Regularly review Log Analytics for unusual access patterns

For production deployments, strongly consider implementing VNet integration or placing the container behind Azure Front Door with additional authentication layers.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Resources

- [Clawdbot Documentation](https://docs.molt.bot/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Container Instances Documentation](https://learn.microsoft.com/azure/container-instances/)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

## License

This deployment template is provided as-is. Please refer to the [Clawdbot license](https://github.com/clawdbot/clawdbot) for the application license.

## Support

For issues related to:
- **Deployment**: Open an issue in this repository
- **Clawdbot application**: Visit [Clawdbot GitHub](https://github.com/clawdbot/clawdbot)
- **Azure services**: Contact [Azure Support](https://azure.microsoft.com/support/)
