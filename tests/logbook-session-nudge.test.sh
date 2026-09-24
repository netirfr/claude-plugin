#!/bin/sh
# Black-box tests for the end-of-session logbook nudge hook.
# Runs the hook against crafted stdin + an isolated data dir, asserts the
# once-per-session, snooze, and used-but-not-published invariants.
set -u

HOOK="$(CDPATH= cd -- "$(dirname -- "$0")/../scripts" && pwd)/logbook-session-nudge.sh"
fail=0

# Every test dir lives under one temp root, removed on exit (including Ctrl-C).
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
trap 'exit 130' INT TERM
# tmpdir <name> -> creates and prints a fresh dir under the temp root
tmpdir() { mkdir -p "$root/$1" && printf '%s' "$root/$1"; }

# run <session_id> <transcript_content> <data_dir> -> prints stdout, sets RC
run() {
  _sid="$1"; _content="$2"; _dir="$3"
  _tr="$(mktemp "$root/transcript.XXXXXX")"
  printf '%s' "$_content" > "$_tr"
  OUT="$(printf '{"session_id":"%s","transcript_path":"%s"}' "$_sid" "$_tr" | CLAUDE_PLUGIN_DATA="$_dir" "$HOOK")"
  RC=$?
  rm -f "$_tr"
}

check() {
  if [ "$1" = "$2" ]; then
    printf 'ok   - %s\n' "$3"
  else
    printf 'FAIL - %s (expected [%s], got [%s])\n' "$3" "$2" "$1"
    fail=1
  fi
}

# 1. Netir used, not published, fresh session -> blocks (exit 0, decision on stdout).
d="$(tmpdir d1)"
run "s1" "used mcp__netir__prepare_logbook_update here" "$d"
check "$RC" "0" "used+unpublished exits 0"
case "$OUT" in *'"decision":"block"'*) check "1" "1" "used+unpublished emits block" ;; *) check "0" "1" "used+unpublished emits block" ;; esac

# 2. Same session again -> sentinel prevents a second nudge (no loop).
run "s1" "used mcp__netir__prepare_logbook_update here" "$d"
check "$RC" "0" "second call same session exits 0"
case "$OUT" in *'"decision"'*) check "0" "1" "second call is silent" ;; *) check "1" "1" "second call is silent" ;; esac

# 3. Snooze marker for today -> silent even on a fresh session.
d2="$(tmpdir d2)"; touch "$d2/snooze-$(date +%Y-%m-%d)"
run "s2" "used mcp__netir__prepare_logbook_update here" "$d2"
case "$OUT" in *'"decision"'*) check "0" "1" "snooze suppresses the nudge" ;; *) check "1" "1" "snooze suppresses the nudge" ;; esac

# 4. Logbook already published this session -> silent.
d3="$(tmpdir d3)"
run "s3" "called publish_logbook_update and it worked" "$d3"
case "$OUT" in *'"decision"'*) check "0" "1" "published session is silent" ;; *) check "1" "1" "published session is silent" ;; esac

# 5. Missing session id -> never fires, exits 0.
d4="$(tmpdir d4)"
OUT="$(printf '{"transcript_path":"/nope"}' | CLAUDE_PLUGIN_DATA="$d4" "$HOOK")"; RC=$?
check "$RC" "0" "missing session id exits 0"
case "$OUT" in *'"decision"'*) check "0" "1" "missing session id is silent" ;; *) check "1" "1" "missing session id is silent" ;; esac

# 6. Readable transcript, but Netir was never used this session -> silent (exit 0).
# Guards the used_netir=0 branch: a session with no Netir tool call must not nudge.
d5="$(tmpdir d5)"
run "s6" "ran some unrelated tools and finished the task" "$d5"
check "$RC" "0" "unused-netir session exits 0"
case "$OUT" in *'"decision"'*) check "0" "1" "unused-netir session is silent" ;; *) check "1" "1" "unused-netir session is silent" ;; esac

# 7. A stop BEFORE any Netir use must not burn the once-per-session nudge: a later
# stop in the SAME session, once Netir has been used, must still nudge.
d6="$(tmpdir d6)"
run "s7" "just chatting, no tools yet" "$d6"
case "$OUT" in *'"decision"'*) check "0" "1" "pre-Netir stop stays silent" ;; *) check "1" "1" "pre-Netir stop stays silent" ;; esac
run "s7" "now used mcp__netir__prepare_logbook_update here" "$d6"
case "$OUT" in *'"decision":"block"'*) check "1" "1" "later Netir use still nudges" ;; *) check "0" "1" "later Netir use still nudges" ;; esac

# 8. A data dir whose path holds a quote and a backslash must still yield valid JSON,
# otherwise Claude Code drops the block decision and the nudge never shows.
d8="$(tmpdir "d8/we\"ird\\dir")"
run "s8" "used mcp__netir__prepare_logbook_update here" "$d8"
if command -v python3 >/dev/null 2>&1; then
  decision="$(printf '%s' "$OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["decision"])' 2>/dev/null)"
  check "$decision" "block" "quote/backslash in data dir keeps the JSON valid"
else
  printf 'skip - python3 absent, JSON validity not checked\n'
fi

if [ "$fail" -eq 0 ]; then printf '\nAll nudge hook tests passed.\n'; else printf '\nnudge hook tests FAILED.\n'; fi
exit "$fail"
