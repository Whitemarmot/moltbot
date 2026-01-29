#!/bin/bash
# Moltbot VPS Setup Script
# This script prepares a fresh VPS for running Moltbot

set -e

echo "🦞 Moltbot VPS Setup"
echo "===================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./setup-vps.sh)"
  exit 1
fi

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
else
  echo "✅ Docker already installed"
fi

# Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
  echo "🐳 Installing Docker Compose..."
  apt-get install -y docker-compose-plugin
else
  echo "✅ Docker Compose already installed"
fi

# Create moltbot user
if ! id "moltbot" &>/dev/null; then
  echo "👤 Creating moltbot user..."
  useradd -m -s /bin/bash moltbot
  usermod -aG docker moltbot
else
  echo "✅ moltbot user already exists"
fi

# Create working directory
WORK_DIR="/opt/moltbot"
echo "📁 Creating working directory: $WORK_DIR"
mkdir -p $WORK_DIR
chown moltbot:moltbot $WORK_DIR

# Setup firewall
if command -v ufw &> /dev/null; then
  echo "🔥 Configuring firewall..."
  ufw allow 22/tcp    # SSH
  ufw allow 80/tcp    # HTTP
  ufw allow 443/tcp   # HTTPS
  ufw allow 18789/tcp # Moltbot Gateway
  ufw --force enable
  echo "✅ Firewall configured"
fi

# Create magento network if it doesn't exist
if ! docker network ls | grep -q magento-network; then
  echo "🌐 Creating magento-network..."
  docker network create magento-network
else
  echo "✅ magento-network already exists"
fi

# Generate gateway token
GATEWAY_TOKEN=$(openssl rand -hex 32)
echo ""
echo "🔐 Generated Gateway Token (save this!):"
echo "   $GATEWAY_TOKEN"
echo ""

# Create .env template
cat > $WORK_DIR/.env.example << 'EOF'
# Moltbot Configuration
MOLTBOT_VERSION=latest

# Gateway Authentication (REQUIRED)
# Generate with: openssl rand -hex 32
CLAWDBOT_GATEWAY_TOKEN=your_gateway_token_here

# Optional: Password for web UI access
CLAWDBOT_GATEWAY_PASSWORD=

# Anthropic API Key (REQUIRED)
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional: Discord Bot Token
DISCORD_BOT_TOKEN=

# Optional: Telegram Bot Token
TELEGRAM_BOT_TOKEN=

# Domain for Traefik (optional)
DOMAIN=example.com

# Watchtower settings (optional)
WATCHTOWER_MONITOR_ONLY=false
EOF

echo "✅ Created .env.example at $WORK_DIR/.env.example"

# Create initial .env with generated token
cat > $WORK_DIR/.env << EOF
MOLTBOT_VERSION=latest
CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN
CLAWDBOT_GATEWAY_PASSWORD=
ANTHROPIC_API_KEY=
DISCORD_BOT_TOKEN=
TELEGRAM_BOT_TOKEN=
DOMAIN=
EOF
chmod 600 $WORK_DIR/.env
chown moltbot:moltbot $WORK_DIR/.env

echo ""
echo "=========================================="
echo "✅ VPS Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit $WORK_DIR/.env and add your ANTHROPIC_API_KEY"
echo "2. Copy docker-compose.prod.yml to $WORK_DIR"
echo "3. Run: cd $WORK_DIR && docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "GitHub Actions Secrets to configure:"
echo "  VPS_HOST: $(hostname -I | awk '{print $1}')"
echo "  VPS_USER: moltbot"
echo "  VPS_SSH_KEY: (your SSH private key)"
echo "  VPS_WORK_DIR: $WORK_DIR"
echo "  CLAWDBOT_GATEWAY_TOKEN: $GATEWAY_TOKEN"
echo "  ANTHROPIC_API_KEY: (your Anthropic API key)"
echo ""
