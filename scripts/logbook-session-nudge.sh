#!/bin/sh
# Netir : rappel de fin de session pour consigner le carnet de mission.
# Se déclenche au plus une fois par session (fichier sentinelle), uniquement si le
# freelance a utilisé Netir pendant la session sans encore publier son carnet.
# Reçoit le JSON du hook Stop sur stdin ; n'écrit sur stdout que pour relancer l'agent.
set -u

input="$(cat)"

# JSON string escaping without jq: backslashes and quotes escaped, control characters dropped.
json_escape() { printf '%s' "$1" | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# Extraction bornée depuis le JSON stdin, sans dépendance à jq.
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -c 128)"
transcript="$(printf '%s' "$input" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -c 4096)"

# Sans identifiant de session, on laisse la session se terminer normalement.
[ -n "$sid" ] || exit 0

data_dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/netir-logbook}"
mkdir -p "$data_dir" 2>/dev/null || true

# Purge des sentinelles anciennes pour borner la taille du dossier.
find "$data_dir" -type f -mtime +7 -delete 2>/dev/null || true

sentinel="$data_dir/nudged-$sid"

# Déjà proposé pour cette session : on autorise l'arrêt.
[ -e "$sentinel" ] && exit 0

# Le freelance a demandé à ne plus être relancé aujourd'hui.
today="$(date +%Y-%m-%d 2>/dev/null || echo unknown)"
[ -e "$data_dir/snooze-$today" ] && exit 0

# On ne relance que si Netir a été utilisé cette session, sans publication de carnet.
used_netir=0
published=0
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  if grep -q "prepare_logbook_update\|publish_logbook_update\|mcp__netir__" "$transcript" 2>/dev/null; then
    used_netir=1
  fi
  if grep -q "publish_logbook_update" "$transcript" 2>/dev/null; then
    published=1
  fi
fi

if [ "$used_netir" -eq 1 ] && [ "$published" -eq 0 ]; then
  # On marque la sentinelle au moment de relancer (et seulement là) : ça suffit à
  # ne jamais boucler — le Stop qui suit la relance verra la sentinelle et s'arrêtera.
  # La poser inconditionnellement la brûlerait dès le premier Stop d'une session
  # (souvent avant tout usage de Netir), et la relance de fin de session ne
  # partirait jamais.
  : > "$sentinel"
  reason="Avant de terminer cette session Netir, lance le skill netir-logbook. Si le freelance ne veut plus être relancé aujourd'hui, crée le fichier $data_dir/snooze-$today avant de terminer."
  # Exit 0 with a decision object on stdout: Claude Code parses stdout for the
  # block decision AND the reason, so the wrap-up guidance reaches the model.
  # The reason embeds $data_dir, which comes from the environment: escape it so a quote
  # or backslash in the path can't break the JSON and silently drop the block decision.
  printf '{"decision":"block","reason":"%s"}\n' "$(json_escape "$reason")"
  exit 0
fi

exit 0
