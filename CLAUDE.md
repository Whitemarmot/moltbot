# CLAUDE.md - Moltbot Deployment Stack

## Project Overview

This repository contains the Docker deployment stack for [Moltbot](https://molt.bot), an open-source personal AI assistant. It is NOT the Moltbot source code itself, but the infrastructure configuration to deploy Moltbot on a VPS with CI/CD automation.

## Repository Structure

```
moltbot/
├── docker-compose.yml       # Local development configuration
├── docker-compose.prod.yml  # Production VPS configuration
├── .env.example             # Environment variables template
├── .github/workflows/
│   ├── deploy.yml           # CI/CD automatic deployment
│   └── update.yml           # Automatic updates check
└── scripts/
    ├── setup-vps.sh         # VPS installation script
    └── onboard.sh           # Channel configuration assistant
```

## Key Concepts

### Docker Services

- **moltbot-gateway**: Main Moltbot service (WebSocket on port 18789)
- **moltbot-cli**: Interactive CLI for configuration (profile: cli)
- **watchtower**: Optional auto-update service (profile: autoupdate)

### Networks

- **moltbot-network**: Internal network for Moltbot services
- **magento-network**: External network to communicate with Magento stack on same server

### Volumes

- **moltbot-config**: Persistent config at `/home/node/.clawdbot`
- **moltbot-workspace**: Workspace at `/home/node/clawd`
- **moltbot-home**: Home directory persistence

## Environment Variables

Required:
- `CLAWDBOT_GATEWAY_TOKEN`: Authentication token (generate with `openssl rand -hex 32`)
- `ANTHROPIC_API_KEY`: Claude API key from Anthropic

Optional:
- `DISCORD_BOT_TOKEN`: For Discord channel
- `TELEGRAM_BOT_TOKEN`: For Telegram channel
- `DOMAIN`: For Traefik HTTPS routing

## Common Commands

```bash
# Start gateway
docker compose -f docker-compose.prod.yml up -d moltbot-gateway

# View logs
docker compose -f docker-compose.prod.yml logs -f moltbot-gateway

# Run CLI commands
docker compose -f docker-compose.prod.yml run --rm moltbot-cli <command>

# Add Discord channel
docker compose -f docker-compose.prod.yml run --rm moltbot-cli channels add --channel discord --token "TOKEN"

# Check health
docker compose -f docker-compose.prod.yml exec moltbot-gateway node dist/index.js health --token "$CLAWDBOT_GATEWAY_TOKEN"
```

## CI/CD Workflow

The `deploy.yml` workflow:
1. Copies config files to VPS via SCP
2. Creates `.env` from GitHub Secrets
3. Pulls latest Moltbot image
4. Restarts the container
5. Verifies health check

Triggered on: push to main/master, or manual dispatch with version selection.

## Integration with Magento

This stack is designed to run alongside a Magento Docker stack on the same server. The `magento-network` allows Moltbot to communicate with Magento containers directly using container names as hostnames.

## Security Notes

- Gateway token required for all API access
- Runs as non-root user (node) inside container
- UFW firewall configured by setup script
- Secrets managed via GitHub Secrets, not committed to repo
