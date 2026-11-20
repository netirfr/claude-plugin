---
name: netir-logbook
description: Consigne l'avancement d'une session de travail dans le carnet de mission Netir du freelance (rapport de période + tâches, et une éventuelle opportunité commerciale réservée à l'apporteur d'affaires), en demandant sur quelle mission si plusieurs sont actives, et ne publie qu'après son accord. Se déclenche quand le freelance termine une session de travail sur une mission Netir, ou quand le rappel de fin de session le demande.
allowed-tools: "AskUserQuestion mcp__netir__prepare_logbook_update"
---

# Carnet de mission Netir — clôture de session

Quand le freelance termine une session de travail sur une mission Netir, propose-lui de consigner ce qui a avancé dans son carnet de mission.

Ne publie qu'après un « oui » explicite du freelance : la publication envoie le rapport par email au client de la mission. S'il décline, termine sans rien écrire dans le carnet.

## Déroulé

1. Appelle `mcp__netir__prepare_logbook_update` pour récupérer les missions actives du freelance, plus le brouillon de rapport en cours et ses tâches (avec leur statut). Sans brouillon, `carried_over_tasks` liste les tâches restées ouvertes au dernier rapport publié : le prochain rapport les reprend d'office.

2. Choisis la mission :
   - **0 mission active** : ne propose rien, arrête-toi.
   - **1 seule mission active** : utilise-la directement, sans poser la question.
   - **Plusieurs missions actives** : demande « Sur quelle mission consigner ce travail ? », une option par mission active (nom + client), plus une option « Aucune, ne rien publier ».

3. Résume l'avancement de la session : propose une liste de tâches à créer ou mettre à jour, chacune avec un statut (`not_started`, `in_progress`, `paused`, `done`, `abandoned`, `blocked`). `paused` est une tâche commencée puis mise de côté : elle ne revient jamais à `not_started`. Une tâche déjà connue (dans le brouillon ou dans `carried_over_tasks`) se met à jour avec son `id`, elle ne se recrée jamais : sans `id` et avec une description reformulée, la publication ajoute une seconde tâche à côté de la tâche reportée. Si c'est pertinent, propose aussi un score de santé de mission (1 à 5), un score de progression (1 à 5) et un point de vigilance.

   Propose en plus une **opportunité** pour l'apporteur d'affaires, mais seulement si la session en contient un signal concret : le client a besoin d'un logiciel, d'une formation, il évoque un nouveau projet ou un déploiement, ou un outil ou un prestataire externe arrive chez lui. Rédige-la en une ou deux phrases factuelles (2 000 caractères au plus, sinon la publication est refusée), en reprenant ce qui a été dit ou vu dans la session. N'en invente jamais une et n'en déduis pas une sans matière concrète : sans signal réel, il n'y a pas d'opportunité, et c'est le cas le plus fréquent.

4. Demande la confirmation (« Je publie ce récap dans ton carnet de mission ? ») avec un aperçu court : une ligne par tâche (titre + statut), puis les scores et le point de vigilance s'il y en a. S'il y a une opportunité, ajoute-la à la fin de l'aperçu, précédée de cette mention : « Opportunité (privée : visible de ton apporteur d'affaires, jamais du client) ». Options : « Publier », « Modifier d'abord », « Ne pas publier ». « Modifier d'abord » permet aussi de retirer ou de reformuler l'opportunité, toujours dans la limite de 2 000 caractères ; montre ensuite l'aperçu corrigé et redemande la confirmation.

5. Si le freelance confirme, appelle `mcp__netir__publish_logbook_update` avec `{ mission_id, period_start, period_end, tasks[], mission_health_score, progress_perception, warnings[], business_opportunity }`, où chaque tâche mise à jour porte son `id`. N'envoie `business_opportunity` que si le freelance a validé une opportunité : sinon, omets le champ. Un seul appel suffit : il crée ou met à jour le brouillon de la période, applique les tâches, et publie.

Pose les questions des étapes 2 et 4 avec `AskUserQuestion` si l'outil est disponible : des options cliquables évitent une réponse ambiguë sur ce qui sera publié. Sans lui (session non interactive), pose-les en texte avec les mêmes options, et attends la réponse.
