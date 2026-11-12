#!/bin/sh
# Netir: end-of-session reminder to fill in the mission logbook.
# Fires at most once per session (sentinel file), only when the freelance used Netir during
# the session without publishing their logbook yet.
# Reads the Stop hook's JSON on stdin; writes to stdout only to send the agent back to work.
set -u

input="$(cat)"

# JSON string escaping without jq: backslashes and quotes escaped, control characters dropped.
json_escape() { printf '%s' "$1" | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# Bounded extraction from the stdin JSON, without jq.
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -c 128)"
transcript="$(printf '%s' "$input" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -c 4096)"

# Without a session id, the session ends normally.
[ -n "$sid" ] || exit 0

data_dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/netir-logbook}"
mkdir -p "$data_dir" 2>/dev/null || true

# Purges old sentinels to bound the folder's size.
find "$data_dir" -type f -mtime +7 -delete 2>/dev/null || true

sentinel="$data_dir/nudged-$sid"

# Already offered in this session: let it stop.
[ -e "$sentinel" ] && exit 0

# The freelance asked not to be reminded again today.
today="$(date +%Y-%m-%d 2>/dev/null || echo unknown)"
[ -e "$data_dir/snooze-$today" ] && exit 0

# Remind only when Netir was used this session and no logbook was published.
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
  # The sentinel is set only when reminding: the next Stop sees it, so it never loops. Set
  # unconditionally, it would burn on a session's first Stop, often before any Netir use.
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
