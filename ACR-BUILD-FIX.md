# Azure Container Registry Build Error Fix

**Error:** `groupadd: GID '1000' already exists`  
**Root Cause:** ACR is using a cached or different Dockerfile (Step 8/18) that doesn't match the current repo

---

## Quick Fix (Do This First)

### Option 1: Use Pre-Built Image (Fastest ⚡)

Skip the ACR build entirely and use the GitHub Container Registry pre-built image:

```bash
cd clawdbot-az-aci

# Deploy with pre-built image
azd down  # Optional: remove old resources

# Re-initialize with GHCR image
azd env new

# Edit .env and set (or let it prompt):
# AZURE_ENV_NAME=clawdbot-dev
# AZURE_LOCATION=eastus

# Deploy
azd up
```

When prompted for container image, use:
```
ghcr.io/roccoren/clawdbot-az-aci:latest
```

**This avoids ACR build entirely!** ✅

---

### Option 2: Clear ACR Build Cache & Rebuild

If you want to use ACR:

```bash
# Get your ACR name from the deployment
ACR_NAME=$(azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME | cut -d'=' -f2 | tr -d '"')

# Purge cached images
az acr run \
  --registry $ACR_NAME \
  --cmd 'acr purge --filter "clawdbot:.*" --ago 0d' \
  .

# Redeploy (will rebuild fresh)
azd up
```

---

### Option 3: Force Local Docker Build (Slowest)

```bash
# Clear Docker cache
docker system prune -a

# Rebuild locally and push to ACR
cd clawdbot-az-aci
.azd/hooks/predeploy.sh

# Then deploy
azd deploy
```

---

## Root Cause Analysis

**Our Dockerfile:**
- Uses `node:20-slim` base image
- Already has `node` user with UID 1000
- Switches to USER node
- Only 34 lines total

**ACR Build Error:**
- Shows "Step 8/18" (18 steps, not 34 lines!)
- Tries to `groupadd --gid 1000`
- This conflicts with existing node user

**Conclusion:** ACR is running a **different Dockerfile** that we didn't push, likely from:
- Cached ACR task definition
- Old build configuration
- Stale ACR build context

---

## Prevention for Future Deployments

### Use Pre-Built Image by Default

Edit `azuredeploy.json`:

```json
"containerImage": {
  "type": "string",
  "defaultValue": "ghcr.io/roccoren/clawdbot-az-aci:latest",
  "metadata": {
    "description": "Pre-built container image from GitHub Container Registry (recommended) or 'acr' to build from ACR"
  }
}
```

### Skip ACR Build Entirely

Edit `azure.yaml`:

```yaml
services:
  clawdbot:
    project: .
    language: docker
    host: containerinstance
    # Skip ACR build, use pre-built image
    docker:
      image: ghcr.io/roccoren/clawdbot-az-aci:latest
```

---

## Current Dockerfile (Correct)

Our Dockerfile is correct and uses the existing node user:

```dockerfile
FROM node:20-slim  # Already has node:1000

RUN apt-get update && apt-get install -y git curl
RUN npm install -g clawdbot

WORKDIR /home/node
ENV NODE_ENV=production

EXPOSE 18789

USER node  # ← Use existing user, don't create new one

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

CMD ["clawdbot", "gateway"]
```

This works perfectly. The issue is ACR has an **old cached build definition**.

---

## Next Steps

**Recommended:**

1. ✅ Use pre-built GHCR image (Option 1 above)
2. ✅ Deploy successfully
3. ✅ Verify Clawdbot runs
4. ✅ Update documentation to recommend GHCR by default

**If you need ACR for some reason:**
- Use Option 2 (clear cache) or Option 3 (rebuild locally)
- Update Azure configuration to skip ACR build tasks

---

## Verification After Deploy

```bash
# Check container is running
az container show \
  --resource-group <your-rg> \
  --name <container-name> \
  --query "containers[0].instanceView.currentState"

# Should show: "Running"

# Check logs
az container logs \
  --resource-group <your-rg> \
  --name <container-name>

# Should show Clawdbot starting successfully
```

---

**TL;DR:** Use GHCR pre-built image (`ghcr.io/roccoren/clawdbot-az-aci:latest`) to avoid ACR build issues entirely! 🚀
