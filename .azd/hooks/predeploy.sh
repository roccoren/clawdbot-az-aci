#!/bin/bash
set -e

echo "Building Docker image..."

# Get the container registry name from azd environment
CONTAINER_REGISTRY=$(azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME | cut -d'=' -f2 | tr -d '"')

if [ -z "$CONTAINER_REGISTRY" ]; then
    echo "Error: Container registry name not found. Make sure provisioning completed successfully."
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
