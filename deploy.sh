#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Clawdbot Azure Container Instance Deploy${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Azure Developer CLI is installed
if ! command -v azd &> /dev/null; then
    echo -e "${RED}Error: Azure Developer CLI (azd) is not installed.${NC}"
    echo "Please install it from: https://aka.ms/azure-dev/install"
    exit 1
fi

# Check if user is logged in
if ! azd auth login --check-status &> /dev/null; then
    echo -e "${YELLOW}You need to login to Azure...${NC}"
    azd auth login
fi

# Check for environment file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}No .env file found. Creating from .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}Please edit .env file with your API keys and configuration.${NC}"
        exit 1
    else
        echo -e "${RED}Error: .env.example file not found.${NC}"
        exit 1
    fi
fi

# Load environment variables
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# Generate gateway token if not set
if [ -z "$CLAWDBOT_GATEWAY_TOKEN" ]; then
    echo -e "${YELLOW}Generating Clawdbot gateway token...${NC}"
    GATEWAY_TOKEN=$(openssl rand -hex 32)
    
    # Update or append the token in .env file
    if grep -q "^CLAWDBOT_GATEWAY_TOKEN=" .env 2>/dev/null; then
        # Update existing line
        sed -i "s/^CLAWDBOT_GATEWAY_TOKEN=.*/CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN/" .env
    else
        # Append new line
        echo "CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN" >> .env
    fi
    
    export CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN
    echo -e "${GREEN}Gateway token generated and saved to .env${NC}"
fi

# Initialize azd environment if not already done
if [ ! -d ".azure" ]; then
    echo -e "${YELLOW}Initializing Azure Developer CLI environment...${NC}"
    azd init
fi

echo ""
echo -e "${GREEN}Step 1: Provisioning Azure resources...${NC}"
azd provision

echo ""
echo -e "${GREEN}Step 2: Building and deploying container...${NC}"
azd deploy

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get the deployment outputs
echo -e "${YELLOW}Getting deployment information...${NC}"
OUTPUTS=$(azd env get-values)

# Extract CLAWDBOT_URL if available
CLAWDBOT_URL=$(echo "$OUTPUTS" | grep CLAWDBOT_URL | cut -d'=' -f2 | tr -d '"')

if [ -n "$CLAWDBOT_URL" ]; then
    echo ""
    echo -e "${GREEN}Clawdbot is now running at: ${CLAWDBOT_URL}${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  SECURITY NOTICE: Keep these credentials secure!${NC}"
    echo -e "${YELLOW}Gateway Token (save this securely): ${CLAWDBOT_GATEWAY_TOKEN}${NC}"
    echo ""
    echo -e "${YELLOW}To access the web interface:${NC}"
    echo -e "1. Open ${CLAWDBOT_URL} in your browser"
    echo -e "2. Paste your gateway token when prompted"
    echo ""
fi

echo -e "${YELLOW}To view logs:${NC}"
echo "azd monitor --logs"
echo ""
echo -e "${YELLOW}To update the deployment:${NC}"
echo "./deploy.sh"
echo ""
echo -e "${YELLOW}To destroy all resources:${NC}"
echo "azd down"
