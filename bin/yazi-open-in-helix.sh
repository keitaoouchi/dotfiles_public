#!/usr/bin/env bash
set -euo pipefail

# Called from yazi keymap to open a file in the Helix pane via cmux.
# Layout: Claude Code (left) | Helix (center) | Yazi (right)
# Usage: yazi-open-in-helix.sh <file-path>

BRIDGE_TMPDIR="${TMPDIR:-/tmp}"
LOG_FILE="${BRIDGE_TMPDIR}/claude-helix-bridge.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [yazi] $*" >> "$LOG_FILE" 2>/dev/null || true
}

# Check dependencies
for cmd in jq cmux; do
  if ! command -v "$cmd" &>/dev/null; then
    log "FATAL: Required command '$cmd' not found in PATH"
    exit 1
  fi
done

FILE_PATH="${1:-}"
if [[ -z "$FILE_PATH" ]]; then
  log "ERROR: No file path argument"
  exit 1
fi

# Resolve to absolute path
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"
fi

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

# --- Find the Helix pane ---
# Manual override
if [[ -n "${CLAUDE_HELIX_SURFACE_ID:-}" ]]; then
  helix_surface="$CLAUDE_HELIX_SURFACE_ID"
else
  identify_json=$(cmux identify 2>/dev/null) || { log "ERROR: cmux identify failed"; exit 1; }
  my_pane=$(echo "$identify_json" | jq -r '.caller.pane_ref // empty')

  # Get all non-self panes and find the one running Helix (or a pager from delta)
  helix_pane=""
  shell_pane=""
  while IFS= read -r pane; do
    local_surface=$(cmux list-pane-surfaces --pane "$pane" 2>/dev/null | grep -oE 'surface:[0-9]+' | head -1)
    [[ -z "$local_surface" ]] && continue
    state=$(detect_surface_state "$local_surface")
    case "$state" in
      helix|pager)
        helix_pane="$pane"
        helix_surface="$local_surface"
        break
        ;;
      shell)
        # Remember last shell pane as fallback (skip first = CC pane)
        if [[ -n "$shell_pane" ]]; then
          # Second shell pane found — more likely to be Helix pane
          helix_pane="$pane"
          helix_surface="$local_surface"
        else
          shell_pane="$pane"
          shell_pane_surface="$local_surface"
        fi
        ;;
    esac
  done < <(cmux list-panes 2>/dev/null | grep -oE 'pane:[0-9]+' | grep -xvF "$my_pane")

  # Fallback: if no helix/pager found, use the shell pane
  # With 2 shell panes, we picked the second one above (more likely Helix)
  # With 1 shell pane, it's the only option
  if [[ -z "$helix_pane" && -n "$shell_pane" ]]; then
    helix_pane="$shell_pane"
    helix_surface="${shell_pane_surface:-}"
  fi

  if [[ -z "${helix_surface:-}" ]]; then
    log "ERROR: No Helix pane found"
    exit 1
  fi
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
    cmux send --surface "$helix_surface" "hx '${FILE_PATH}'\r" 2>/dev/null
    ;;
  shell)
    cmux send --surface "$helix_surface" "hx '${FILE_PATH}'\r" 2>/dev/null
    ;;
esac
