# Plugin Netir pour Claude Code

Ce plugin branche ton agent (Claude Code) sur ta plateforme Netir. Il apporte deux choses :

- **Le carnet de mission en fin de session** : quand tu termines une session de travail, l'agent te propose de consigner ce qui a avancé dans ton carnet de mission. S'il détecte plusieurs missions actives, il te demande laquelle avant d'écrire, et ne publie jamais sans ton accord.
- **L'accès à ton cockpit Netir** : via le MCP Netir, l'agent peut gérer ton carnet de mission, tes devis et tes factures.

## Prérequis

Une clé API Netir. Génère-la depuis tes réglages Netir (« Connecter mon agent »), elle commence par `nk_`.

## Installation

Deux morceaux : le serveur MCP (l'accès à Netir) et le plugin (le carnet de mission en fin de session).

### 1. Le serveur MCP

Le plus simple, en une commande :

```sh
claude mcp add --transport http netir "$NETIR_API_URL/api/v3/mcp" \
  --header "Authorization: Bearer $NETIR_API_KEY"
```

où `NETIR_API_URL` est l'adresse de l'API Netir et `NETIR_API_KEY` ta clé `nk_…`. La clé étant propre à chaque freelance, elle reste dans ta configuration locale (`claude mcp add`), jamais dans le plugin partagé.

### 2. Le plugin

Le plugin n'apporte que le carnet de mission de fin de session (un skill et un hook `Stop`, sans secret) ; la connexion à Netir reste celle de l'étape 1.

```sh
claude plugin marketplace add https://gitlab.com/getnobullshit/platform.git
claude plugin install netir@netir
```

## Ce qui se passe en fin de session

À la fin d'une session où tu as travaillé avec Netir, l'agent te propose, une seule fois, de mettre à jour ton carnet de mission. Tu peux accepter, ajuster le contenu, ou refuser. Pour ne plus être relancé aujourd'hui, crée le fichier `snooze-AAAA-MM-JJ` (date du jour) dans le dossier de données du plugin.

## À confirmer avant distribution

- L'adresse publique de l'API Netir (`NETIR_API_URL`).
- L'accès au dépôt du marketplace : `claude plugin marketplace add` doit viser un dépôt que le freelance peut cloner, et son manifeste `.claude-plugin/marketplace.json` doit être à la racine du dépôt. Le monorepo `getnobullshit/platform` étant privé, publier le plugin sur un dépôt (ou une URL) accessible aux freelances avant de communiquer l'étape 2.
