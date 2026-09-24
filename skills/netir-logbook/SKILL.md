---
name: netir-logbook
description: Consigne l'avancement d'une session de travail dans le carnet de mission Netir du freelance (rapport de période + tâches), en demandant sur quelle mission si plusieurs sont actives, et ne publie qu'après son accord. Se déclenche quand le freelance termine une session de travail sur une mission Netir, ou quand le rappel de fin de session le demande.
allowed-tools: "AskUserQuestion mcp__netir__prepare_logbook_update"
---

# Carnet de mission Netir — clôture de session

Quand le freelance termine une session de travail sur une mission Netir, propose-lui de consigner ce qui a avancé dans son carnet de mission.

Ne publie qu'après un « oui » explicite du freelance : la publication envoie le rapport par email au client de la mission. S'il décline, termine sans rien écrire dans le carnet.

## Déroulé

1. Appelle `mcp__netir__prepare_logbook_update` pour récupérer les missions actives du freelance, plus le brouillon de rapport en cours et ses tâches (avec leur statut).

2. Choisis la mission :
   - **0 mission active** : ne propose rien, arrête-toi.
   - **1 seule mission active** : utilise-la directement, sans poser la question.
   - **Plusieurs missions actives** : demande « Sur quelle mission consigner ce travail ? », une option par mission active (nom + client), plus une option « Aucune, ne rien publier ».

3. Résume l'avancement de la session : propose une liste de tâches à créer ou mettre à jour, chacune avec un statut (`not_started`, `in_progress`, `done`, `abandoned`, `blocked`). Si c'est pertinent, propose aussi un score de santé de mission (1 à 5), un score de progression (1 à 5) et un point de vigilance.

4. Demande la confirmation (« Je publie ce récap dans ton carnet de mission ? ») avec un aperçu court : une ligne par tâche (titre + statut), puis les scores et le point de vigilance s'il y en a. Options : « Publier », « Modifier d'abord », « Ne pas publier ».

5. Si le freelance confirme, appelle `mcp__netir__publish_logbook_update` avec `{ mission_id, period_start, period_end, tasks[], mission_health_score, progress_perception, warnings[] }`. Un seul appel suffit : il crée ou met à jour le brouillon de la période, applique les tâches, et publie.

Pose les questions des étapes 2 et 4 avec `AskUserQuestion` si l'outil est disponible : des options cliquables évitent une réponse ambiguë sur ce qui sera publié. Sans lui (session non interactive), pose-les en texte avec les mêmes options, et attends la réponse.
