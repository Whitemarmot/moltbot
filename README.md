# Moltbot Deployment Stack

Stack de deploiement Docker pour [Moltbot](https://molt.bot) - votre assistant AI personnel open-source.

## Qu'est-ce que Moltbot ?

Moltbot (anciennement Clawdbot) est un assistant AI personnel qui:
- Tourne localement sur votre machine/serveur
- Se connecte a plusieurs plateformes: Discord, Telegram, WhatsApp, Slack, etc.
- Memorise vos preferences et contexte 24/7
- Execute des commandes systeme et navigue sur le web
- Est entierement open-source et respecte votre vie privee

## Structure du Projet

```
moltbot/
├── docker-compose.yml       # Configuration developpement local
├── docker-compose.prod.yml  # Configuration production VPS
├── .env.example             # Template des variables d'environnement
├── .github/
│   └── workflows/
│       ├── deploy.yml       # CI/CD deploiement automatique
│       └── update.yml       # Mise a jour automatique
└── scripts/
    ├── setup-vps.sh         # Script d'installation VPS
    └── onboard.sh           # Assistant de configuration
```

## Pre-requis

- VPS avec Docker et Docker Compose
- Cle API Anthropic (Claude)
- [Optionnel] Tokens pour Discord/Telegram

## Installation Rapide

### 1. Preparer le VPS

```bash
# Sur le VPS (en tant que root)
curl -fsSL https://raw.githubusercontent.com/Whitemarmot/moltbot/master/scripts/setup-vps.sh | sudo bash
```

Ou manuellement:
```bash
git clone https://github.com/Whitemarmot/moltbot.git /opt/moltbot
cd /opt/moltbot
chmod +x scripts/*.sh
sudo ./scripts/setup-vps.sh
```

### 2. Configurer les Variables

```bash
cd /opt/moltbot
cp .env.example .env
nano .env  # Ajouter vos tokens
```

Variables requises:
- `CLAWDBOT_GATEWAY_TOKEN` - Token d'authentification (genere par le script)
- `ANTHROPIC_API_KEY` - Cle API Anthropic

### 3. Lancer Moltbot

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 4. Configurer les Canaux

```bash
./scripts/onboard.sh
```

Ou via CLI:
```bash
# Discord
docker compose -f docker-compose.prod.yml run --rm moltbot-cli channels add --channel discord --token "VOTRE_TOKEN"

# Telegram
docker compose -f docker-compose.prod.yml run --rm moltbot-cli channels add --channel telegram --token "VOTRE_TOKEN"

# WhatsApp (QR code)
docker compose -f docker-compose.prod.yml run --rm moltbot-cli channels login
```

## CI/CD avec GitHub Actions

### Secrets a Configurer

Dans GitHub > Settings > Secrets and variables > Actions:

| Secret | Description |
|--------|-------------|
| `VPS_HOST` | IP ou domaine du VPS |
| `VPS_USER` | Utilisateur SSH (moltbot) |
| `VPS_SSH_KEY` | Cle SSH privee |
| `VPS_PORT` | Port SSH (optionnel, defaut: 22) |
| `VPS_WORK_DIR` | Repertoire de travail (/opt/moltbot) |
| `CLAWDBOT_GATEWAY_TOKEN` | Token du gateway |
| `ANTHROPIC_API_KEY` | Cle API Anthropic |
| `DISCORD_BOT_TOKEN` | Token Discord (optionnel) |
| `TELEGRAM_BOT_TOKEN` | Token Telegram (optionnel) |
| `DOMAIN` | Domaine pour Traefik (optionnel) |

### Deploiement

Le deploiement est automatique a chaque push sur `main`. Vous pouvez aussi:

```bash
# Declencher manuellement avec une version specifique
gh workflow run deploy.yml -f moltbot_version=beta
```

## Integration avec Magento

Le docker-compose.prod.yml est configure pour se connecter au reseau `magento-network`. Si votre Magento tourne sur Docker:

```bash
# Verifier que le reseau existe
docker network ls | grep magento

# Sinon, le creer
docker network create magento-network
```

Moltbot peut ensuite communiquer avec Magento via le nom de container:
```
http://magento-container:80
```

## Commandes Utiles

```bash
# Voir les logs
docker compose -f docker-compose.prod.yml logs -f moltbot-gateway

# Redemarrer
docker compose -f docker-compose.prod.yml restart moltbot-gateway

# Mise a jour manuelle
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# Acceder au CLI
docker compose -f docker-compose.prod.yml run --rm moltbot-cli

# Verifier la sante
docker compose -f docker-compose.prod.yml exec moltbot-gateway node dist/index.js health --token "$CLAWDBOT_GATEWAY_TOKEN"

# Activer les mises a jour automatiques (Watchtower)
docker compose -f docker-compose.prod.yml --profile autoupdate up -d
```

## Control UI

Accedez a l'interface web:
- **Local:** http://localhost:18789/
- **Distant:** https://moltbot.votre-domaine.com/ (avec Traefik)

Collez votre `CLAWDBOT_GATEWAY_TOKEN` dans Settings pour vous authentifier.

## Architecture

```
┌──────────────────────────────────────────────┐
│                    VPS                        │
│                                              │
│  ┌─────────────┐     ┌─────────────────────┐ │
│  │   Traefik   │────▶│  moltbot-gateway    │ │
│  │  (reverse   │     │  - Control UI       │ │
│  │   proxy)    │     │  - WebSocket API    │ │
│  └─────────────┘     │  - Channel handlers │ │
│                      └──────────┬──────────┘ │
│                                 │            │
│        ┌────────────────────────┼───────┐    │
│        │     magento-network    │       │    │
│        │                        ▼       │    │
│        │              ┌─────────────┐   │    │
│        │              │   Magento   │   │    │
│        │              │   Stack     │   │    │
│        │              └─────────────┘   │    │
│        └────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

## Securite

- Le token gateway est requis pour toute interaction
- Les volumes Docker isolent les donnees
- L'utilisateur `node` non-root dans le container
- Firewall UFW configure par le script d'installation
- HTTPS via Traefik avec Let's Encrypt (optionnel)

## Ressources

- [Documentation Moltbot](https://docs.molt.bot/)
- [GitHub Moltbot](https://github.com/moltbot/moltbot)
- [Discord Community](https://discord.gg/moltbot)

## License

MIT
