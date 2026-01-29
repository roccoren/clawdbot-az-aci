# Use official Node.js LTS image
FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install clawdbot globally
RUN npm install -g clawdbot

# Create directories for persistent data
RUN mkdir -p /home/node/.clawdbot

# Set working directory to node user home
WORKDIR /home/node

# Set environment variables
ENV NODE_ENV=production
ENV CLAWDBOT_HOME=/home/node/.clawdbot

# Expose the default clawdbot port
EXPOSE 18789

# Switch to non-root user
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:18789/ || exit 1

# Start clawdbot gateway
CMD ["clawdbot", "gateway"]
