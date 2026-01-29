#!/bin/bash
# Moltbot Onboarding Script
# Run this after initial deployment to configure channels

set -e

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

echo "🦞 Moltbot Onboarding"
echo "===================="
echo ""

# Check if gateway is running
if ! docker ps | grep -q moltbot-gateway; then
  echo "❌ Moltbot gateway is not running!"
  echo "Start it first: docker compose -f $COMPOSE_FILE up -d moltbot-gateway"
  exit 1
fi

echo "Select what you want to configure:"
echo ""
echo "1) Run full onboarding wizard"
echo "2) Add Discord channel"
echo "3) Add Telegram channel"
echo "4) Add WhatsApp channel (QR code)"
echo "5) Check gateway health"
echo "6) View logs"
echo "0) Exit"
echo ""

read -p "Choice: " choice

case $choice in
  1)
    echo "Starting onboarding wizard..."
    docker compose -f $COMPOSE_FILE run --rm moltbot-cli onboard
    ;;
  2)
    read -p "Enter Discord bot token: " discord_token
    docker compose -f $COMPOSE_FILE run --rm moltbot-cli channels add --channel discord --token "$discord_token"
    ;;
  3)
    read -p "Enter Telegram bot token: " telegram_token
    docker compose -f $COMPOSE_FILE run --rm moltbot-cli channels add --channel telegram --token "$telegram_token"
    ;;
  4)
    echo "Scan the QR code with WhatsApp..."
    docker compose -f $COMPOSE_FILE run --rm moltbot-cli channels login
    ;;
  5)
    echo "Checking gateway health..."
    source .env 2>/dev/null || true
    docker compose -f $COMPOSE_FILE exec moltbot-gateway node dist/index.js health --token "$CLAWDBOT_GATEWAY_TOKEN"
    ;;
  6)
    docker compose -f $COMPOSE_FILE logs -f moltbot-gateway
    ;;
  0)
    echo "Bye!"
    exit 0
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

echo ""
echo "✅ Done!"
