---
name: netir-logbook
description: Consigner l'avancement d'une session de travail dans le carnet de mission Netir du freelance (rapport de période + tâches), en demandant sur quelle mission si plusieurs sont actives. À déclencher quand le freelance termine une session de travail sur une mission Netir.
when_to_use: En fin de session de travail sur une mission Netir, pour proposer de publier l'évolution des tâches dans le carnet de mission.
allowed-tools: "AskUserQuestion mcp__netir__prepare_logbook_update mcp__netir__publish_logbook_update"
---

# Carnet de mission Netir — clôture de session

Quand le freelance termine une session de travail sur une mission Netir, propose-lui de consigner ce qui a avancé dans son carnet de mission. Ne publie **jamais** sans son accord explicite.

## Déroulé

1. Appelle `mcp__netir__prepare_logbook_update` pour récupérer les missions actives du freelance, plus le brouillon de rapport en cours et ses tâches (avec leur statut).

2. Choisis la mission :
   - **0 mission active** : ne propose rien, arrête-toi.
   - **1 seule mission active** : utilise-la directement, sans poser la question.
   - **Plusieurs missions actives** : pose une question via **`AskUserQuestion`** (« Sur quelle mission consigner ce travail ? »), une option par mission active (nom + client), plus une option « Aucune, ne rien publier ».

3. Résume l'avancement de la session : propose une liste de tâches à créer ou mettre à jour, chacune avec un statut (`not_started`, `in_progress`, `done`, `abandoned`, `blocked`). Si c'est pertinent, propose aussi un score de santé de mission (1 à 5), un score de progression (1 à 5) et un point de vigilance.

4. Demande la confirmation via **`AskUserQuestion`** (« Je publie ce récap dans ton carnet de mission ? »), en montrant un aperçu du contenu. Options : « Publier », « Modifier d'abord », « Ne pas publier ».

5. Si le freelance confirme, appelle `mcp__netir__publish_logbook_update` avec `{ mission_id, period_start, period_end, tasks[], mission_health_score, progress_perception, warnings[] }`. Un seul appel suffit : il crée ou met à jour le brouillon de la période, applique les tâches, et publie.

## Règles

- Le choix de la mission et la confirmation passent **toujours** par `AskUserQuestion`, jamais par une question en texte libre.
- Ne publie jamais sans un « oui » explicite.
- Si le freelance décline, termine sans rien écrire dans le carnet.
