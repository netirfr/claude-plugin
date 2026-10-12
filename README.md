# Plugin Netir pour Claude Code

Ce plugin branche ton agent (Claude Code) sur ta plateforme Netir. Il apporte deux choses :

- **Le carnet de mission en fin de session** : quand tu termines une session de travail, l'agent te propose de consigner ce qui a avancé dans ton carnet de mission. S'il détecte plusieurs missions actives, il te demande laquelle avant d'écrire, et ne publie jamais sans ton accord.
- **L'accès à ton cockpit Netir** : via le MCP Netir, l'agent peut gérer ton carnet de mission, tes devis et tes factures.

## Prérequis

Une clé API Netir. Génère-la depuis tes réglages Netir (« Connecter mon agent »), elle commence par `nk_`.

## Installation

Deux morceaux : le serveur MCP (l'accès à Netir) et le plugin (le carnet de mission en fin de session).

### 1. Le serveur MCP

Le plus simple, en une commande (la page « Connecter mon agent » l'affiche aussi, clé comprise, prête à copier) :

```sh
claude mcp add --transport http netir "https://app.netir.fr/api/v3/mcp" \
  --header "Authorization: Bearer $NETIR_API_KEY"
```

où `NETIR_API_KEY` est ta clé `nk_…`. La clé étant propre à chaque freelance, elle reste dans ta configuration locale (`claude mcp add`), jamais dans le plugin partagé.

### 2. Le plugin

Le plugin n'apporte que le carnet de mission de fin de session (un skill et un hook `Stop`, sans secret) ; la connexion à Netir reste celle de l'étape 1.

```sh
claude plugin marketplace add https://github.com/netirfr/claude-plugin.git
claude plugin install netir@netir
```

## Ce qui se passe en fin de session

À la fin d'une session où tu as travaillé avec Netir, l'agent te propose, une seule fois, de mettre à jour ton carnet de mission. Tu peux accepter, ajuster le contenu, ou refuser.

Les tâches restées ouvertes au rapport précédent (« reportées ») sont reprises telles quelles : l'agent les fait avancer (en cours, terminée, bloquée, abandonnée) au lieu d'en créer de nouvelles, ton carnet reste sans doublon.

Si la session fait apparaître une opportunité commerciale concrète (besoin de logiciel ou de formation, nouveau projet, prestataire qui arrive chez ton client), l'agent la propose aussi dans l'aperçu. Elle part à ton apporteur d'affaires, jamais au client, et tu peux la retirer ou la reformuler avant de publier. Sans signal réel dans la session, il n'en propose pas.

Pour ne plus être relancé aujourd'hui, crée le fichier `snooze-AAAA-MM-JJ` (date du jour) dans le dossier de données du plugin : `$CLAUDE_PLUGIN_DATA`, ou à défaut `$TMPDIR/netir-logbook` (`/tmp/netir-logbook` si `TMPDIR` n'est pas défini).

## Distribution (miroir public)

Le monorepo `getnobullshit/platform` est privé, donc les freelances ne peuvent pas le cloner comme marketplace. Ce dossier `claude-plugin/netir/` est publié en lecture seule sur **`https://github.com/netirfr/claude-plugin`** par un *subtree split* Symfony-like (`splitsh-lite`), piloté par la CI (`claude-plugin/.gitlab-ci.yml`) :

- **Mise à jour continue** : à chaque commit sur `main` qui touche `claude-plugin/netir/**`, la CI resplit et pousse le résultat sur `main` du dépôt GitHub. Le monorepo reste la source unique de vérité, le dépôt GitHub est un miroir jamais édité à la main.
- **Release** : un tag `netir-plugin-vX.Y.Z` sur le monorepo pousse le même split sur un tag `vX.Y.Z` du dépôt GitHub ; un workflow GitHub Actions (`.github/workflows/release.yml`) crée alors la release. Aligner ce tag avec le champ `version` de `.claude-plugin/plugin.json` et de `.claude-plugin/marketplace.json`.

Le push CI s'authentifie par une **clé de déploiement SSH** (write) portée par le dépôt GitHub, sans token à faire tourner : la clé privée vit dans la variable CI `GITHUB_DEPLOY_KEY_B64` (masquée + protégée). La release GitHub s'appuie sur le `GITHUB_TOKEN` intégré au runner Actions.

Le dossier est auto-suffisant comme marketplace. Son `.claude-plugin/marketplace.json` (à la racine du split) déclare le plugin `netir` avec `source: "."`. Le plugin ne contient aucun secret (la clé du freelance reste dans `claude mcp add`), sa publication publique est donc sans risque.
