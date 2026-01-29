#!/bin/bash
set -e

echo "Building Docker image..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running."
    echo "Please start Docker and try again."
    exit 1
fi

# Get the container registry name from azd environment
CONTAINER_REGISTRY=$(azd env get-values 2>/dev/null | grep AZURE_CONTAINER_REGISTRY_NAME | cut -d'=' -f2 | tr -d '"')

if [ -z "$CONTAINER_REGISTRY" ]; then
    echo "Error: Container registry name not found."
    echo "Make sure provisioning completed successfully."
    exit 1
fi

# Login to ACR
echo "Logging in to Azure Container Registry..."
az acr login --name $CONTAINER_REGISTRY

# Build and tag the image
IMAGE_NAME="${CONTAINER_REGISTRY}.azurecr.io/clawdbot:latest"
echo "Building image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

# Push the image to ACR
echo "Pushing image to Azure Container Registry..."
docker push $IMAGE_NAME

echo "Docker image built and pushed successfully!"
