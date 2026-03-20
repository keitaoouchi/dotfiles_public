#!/usr/bin/env bash
set -euo pipefail

# Called from yazi keymap to open a file in the Helix pane via cmux.
# Usage: yazi-open-in-helix.sh <file-path>

FILE_PATH="${1:-}"
if [[ -z "$FILE_PATH" ]]; then
  exit 1
fi

# Resolve to absolute path
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"
fi

BRIDGE_TMPDIR="${TMPDIR:-/tmp}"
LOG_FILE="${BRIDGE_TMPDIR}/claude-helix-bridge.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [yazi] $*" >> "$LOG_FILE" 2>/dev/null || true
}

# Detect surface state (same logic as bridge script)
detect_surface_state() {
  local surface="$1"
  local screen
  screen=$(cmux read-screen --surface "$surface" 2>/dev/null) || { echo "shell"; return; }
  if echo "$screen" | tail -3 | grep -qE '\b(NOR|INS|SEL)\b'; then
    echo "helix"
  elif echo "$screen" | tail -3 | grep -qE '(^\(END\)|^:|lines [0-9]|byte [0-9]|press RETURN|press h for help)'; then
    echo "pager"
  else
    echo "shell"
  fi
}

# Find the Helix pane (center pane = not ours, not the rightmost)
# In 3-pane layout: pane:1 (CC), pane:2 (Helix), pane:3 (Yazi)
# Yazi is in the rightmost pane, so we want the middle one.
identify_json=$(cmux identify 2>/dev/null) || { log "ERROR: cmux identify failed"; exit 1; }
my_pane=$(echo "$identify_json" | jq -r '.caller.pane_ref // empty')

# Get all panes except ours, take the first one (should be the Helix/center pane)
helix_pane=$(cmux list-panes 2>/dev/null | grep -oE 'pane:[0-9]+' | grep -xvF "$my_pane" | head -1)
if [[ -z "$helix_pane" ]]; then
  log "ERROR: No other pane found for Helix"
  exit 1
fi

helix_surface=$(cmux list-pane-surfaces --pane "$helix_pane" 2>/dev/null | grep -oE 'surface:[0-9]+' | head -1)
if [[ -z "$helix_surface" ]]; then
  log "ERROR: No surface in $helix_pane"
  exit 1
fi

state=$(detect_surface_state "$helix_surface")
log "OPEN: $FILE_PATH (surface=$helix_surface, state=$state)"

case "$state" in
  helix)
    cmux send-key --surface "$helix_surface" "Escape" 2>/dev/null
    sleep 0.05
    cmux send --surface "$helix_surface" ":open \"${FILE_PATH}\"\r" 2>/dev/null
    ;;
  pager)
    cmux send-key --surface "$helix_surface" "q" 2>/dev/null
    sleep 0.1
    cmux send --surface "$helix_surface" "hx \"${FILE_PATH}\"\r" 2>/dev/null
    ;;
  shell)
    cmux send --surface "$helix_surface" "hx \"${FILE_PATH}\"\r" 2>/dev/null
    ;;
esac
