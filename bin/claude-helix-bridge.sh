#!/usr/bin/env bash
set -euo pipefail

# Only run inside cmux (skip in IDE terminals like IntelliJ)
if [[ -z "${CMUX_SURFACE_ID:-}" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP: not inside cmux (CMUX_SURFACE_ID unset)" >> "${TMPDIR:-/tmp}/claude-helix-bridge.log"
  exit 0
fi

# Use macOS per-user TMPDIR for safety (avoids /tmp symlink attacks, session isolation)
BRIDGE_TMPDIR="${TMPDIR:-/tmp}"
LOG_FILE="${BRIDGE_TMPDIR}/claude-helix-bridge.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null || true
}

# Check required dependencies
for cmd in jq cmux delta; do
  if ! command -v "$cmd" &>/dev/null; then
    log "FATAL: Required command '$cmd' not found in PATH"
    exit 1
  fi
done

# Read stdin JSON (Claude Code hook input)
HOOK_INPUT=$(cat)
if [[ -z "$HOOK_INPUT" ]]; then
  log "ERROR: No input received on stdin"
  exit 1
fi
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "unknown"')

DIFF_FILE="${BRIDGE_TMPDIR}/claude-helix-delta-${SESSION_ID}.diff"

# --- Surface state detection via screen content ---
# Returns: "helix", "pager", or "shell"
detect_surface_state() {
  local surface="$1"
  local screen
  screen=$(cmux read-screen --surface "$surface" 2>/dev/null) || { echo "shell"; return; }

  # Helix status bar shows mode indicators at the bottom (e.g. "NOR", "INS", "SEL")
  # along with file path and cursor position like "1 sel 1:1"
  if echo "$screen" | tail -3 | grep -qE '\b(NOR|INS|SEL)\b'; then
    echo "helix"
  # less shows colon prompt ":" at bottom, or "(END)", or line position
  elif echo "$screen" | tail -3 | grep -qE '(^\(END\)|^:|lines [0-9]|byte [0-9]|press RETURN|press h for help)'; then
    echo "pager"
  else
    echo "shell"
  fi
}

# --- Right pane detection (3-pane layout: CC | Helix | Yazi) ---
get_helix_surface_id() {
  # Manual override
  if [[ -n "${CLAUDE_HELIX_SURFACE_ID:-}" ]]; then
    echo "$CLAUDE_HELIX_SURFACE_ID"
    return 0
  fi

  # Check cache (validate that the cached surface still exists)
  local cache_file="${BRIDGE_TMPDIR}/claude-helix-surface-${SESSION_ID}"
  if [[ -f "$cache_file" ]]; then
    local cached_surface
    cached_surface=$(cat "$cache_file")
    # Verify the surface is still listed in some pane
    if cmux list-panes 2>/dev/null | grep -q . && \
       cmux list-pane-surfaces 2>/dev/null | grep -qF "$cached_surface"; then
      echo "$cached_surface"
      return 0
    else
      log "CACHE: stale surface $cached_surface, re-detecting"
      rm -f "$cache_file"
    fi
  fi

  # Auto-detect: get current pane (CC pane) from cmux identify JSON
  local identify_json identify_err
  identify_err=$(mktemp "${BRIDGE_TMPDIR}/claude-helix-err.XXXXXX")
  identify_json=$(cmux identify 2>"$identify_err") || true
  if [[ -z "$identify_json" ]]; then
    log "ERROR: cmux identify failed: $(cat "$identify_err" 2>/dev/null)"
    rm -f "$identify_err"
    return 1
  fi
  rm -f "$identify_err"

  # Get all panes, find the first one that is not ours (in 3-pane layout, this is the Helix pane)
  # cmux list-panes output: "* pane:1  [1 surface]  [focused]\n  pane:2  [1 surface]"
  local my_pane
  my_pane=$(echo "$identify_json" | jq -r '.caller.pane_ref // empty')

  local other_pane
  other_pane=$(cmux list-panes 2>/dev/null | grep -oE 'pane:[0-9]+' | grep -xvF "$my_pane" | head -1)
  if [[ -z "$other_pane" ]]; then
    # No other pane - create a right split
    # cmux new-pane returns: "OK surface:N pane:N workspace:N"
    log "SPLIT: Creating right pane for Helix"
    local new_pane_output
    new_pane_output=$(cmux new-pane --direction right 2>&1) || {
      log "ERROR: cmux new-pane failed: $new_pane_output"
      return 1
    }
    log "SPLIT: new-pane output='${new_pane_output}'"

    # Parse surface and pane directly from output
    local created_surface created_pane
    created_surface=$(echo "$new_pane_output" | grep -oE 'surface:[0-9]+')
    created_pane=$(echo "$new_pane_output" | grep -oE 'pane:[0-9]+')

    if [[ -z "$created_surface" || -z "$created_pane" ]]; then
      log "ERROR: Could not parse new-pane output"
      return 1
    fi

    # Wait for shell to be ready in the new pane
    local retries=0
    while (( retries < 30 )); do
      if cmux read-screen --surface "$created_surface" 2>/dev/null | grep -qE '[$#❯%]'; then
        break
      fi
      sleep 0.1
      retries=$(( retries + 1 ))
    done
    if (( retries >= 30 )); then
      log "WARN: Shell in $created_surface may not be ready after ${retries} retries (3s timeout)"
    else
      log "SPLIT: shell ready after ${retries} retries (surface=$created_surface)"
    fi

    # Create Yazi pane (rightmost pane in 3-pane layout: CC | Helix | Yazi)
    log "SPLIT: Creating right pane for Yazi"
    local yazi_pane_output
    yazi_pane_output=$(cmux new-pane --direction right 2>&1) || {
      log "WARN: cmux new-pane for yazi failed: $yazi_pane_output"
      # Don't return error - Helix pane is ready, yazi is optional
    }
    if [[ -n "$yazi_pane_output" ]]; then
      local yazi_surface
      yazi_surface=$(echo "$yazi_pane_output" | grep -oE 'surface:[0-9]+')
      if [[ -n "$yazi_surface" ]]; then
        # Wait for shell ready in yazi pane
        local yazi_retries=0
        while (( yazi_retries < 30 )); do
          if cmux read-screen --surface "$yazi_surface" 2>/dev/null | grep -qE '[$#❯%]'; then
            break
          fi
          sleep 0.1
          yazi_retries=$(( yazi_retries + 1 ))
        done
        # Launch yazi
        cmux send --surface "$yazi_surface" "yazi\r" 2>/dev/null
        log "SPLIT: launched yazi (surface=$yazi_surface)"
      fi
    fi

    # Focus back to CC pane (after both panes are created)
    if ! cmux focus-pane --pane "$my_pane" > /dev/null 2>&1; then
      log "WARN: Failed to restore focus to Claude Code pane ($my_pane)"
    fi

    # Return the Helix surface directly (skip further detection)
    echo "$created_surface" > "$cache_file"
    echo "$created_surface"
    return 0
  fi

  # Get the surface in the other pane
  # cmux list-pane-surfaces output: "* surface:2  ~/.dotfiles_public  [selected]"
  local helix_surface
  helix_surface=$(cmux list-pane-surfaces --pane "$other_pane" 2>/dev/null | grep -oE 'surface:[0-9]+' | head -1)
  if [[ -z "$helix_surface" ]]; then
    log "WARN: No surface found in $other_pane"
    return 1
  fi

  echo "$helix_surface" > "$cache_file"
  echo "$helix_surface"
}

# --- Show diff with delta in the right pane ---
show_diff_in_pane() {
  local surface_ref="$1"
  local diff_content="$2"
  local file_path="$3"
  local state
  state=$(detect_surface_state "$surface_ref")
  log "STATE: surface=$surface_ref state=$state"

  case "$state" in
    helix)
      # Helix is running - use :sh to run delta
      cmux send-key --surface "$surface_ref" "Escape" 2>/dev/null
      sleep 0.05
      cmux send --surface "$surface_ref" ":sh delta --side-by-side --paging always < \"${DIFF_FILE}\"\r" 2>/dev/null
      ;;
    pager)
      # less/pager is running (previous delta) - quit it first, then send new command
      cmux send-key --surface "$surface_ref" "q" 2>/dev/null
      sleep 0.1
      cmux send --surface "$surface_ref" "delta --side-by-side --paging always < \"${DIFF_FILE}\"\r" 2>/dev/null
      ;;
    shell)
      # Shell prompt - send command directly
      cmux send --surface "$surface_ref" "delta --side-by-side --paging always < \"${DIFF_FILE}\"\r" 2>/dev/null
      ;;
  esac
}

# --- Send file open to Helix ---
open_in_helix() {
  local surface_ref="$1"
  local file_path="$2"
  local state
  state=$(detect_surface_state "$surface_ref")
  log "STATE: surface=$surface_ref state=$state (open_in_helix)"

  case "$state" in
    helix)
      # Helix is running - send :open command
      cmux send-key --surface "$surface_ref" "Escape" 2>/dev/null
      sleep 0.05
      cmux send --surface "$surface_ref" ":open \"${file_path}\"\r" 2>/dev/null
      ;;
    pager)
      # Quit pager first, then launch helix
      cmux send-key --surface "$surface_ref" "q" 2>/dev/null
      sleep 0.1
      log "LAUNCH: hx ${file_path} (after quitting pager, surface=$surface_ref)"
      cmux send --surface "$surface_ref" "hx \"${file_path}\"\r" 2>/dev/null
      ;;
    shell)
      # Shell prompt - launch hx with the file
      log "LAUNCH: hx ${file_path} (shell prompt, surface=$surface_ref)"
      if ! send_result=$(cmux send --surface "$surface_ref" "hx \"${file_path}\"\r" 2>&1); then
        log "ERROR: Failed to launch helix: $send_result"
        return 1
      fi
      log "LAUNCH: cmux send result='${send_result}'"
      ;;
  esac
}

# --- Main ---
MODE="${1:-}"
case "$MODE" in
  post-tool-use)
    TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
    FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')

    if [[ -z "$FILE_PATH" ]]; then
      log "SKIP: no file_path in tool_input (tool=$TOOL_NAME)"
      exit 0
    fi

    # Resolve to absolute path
    if [[ "$FILE_PATH" != /* ]]; then
      CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty')
      FILE_PATH="${CWD}/${FILE_PATH}"
    fi

    SURFACE_ID=$(get_helix_surface_id) || {
      log "ERROR: Could not detect helix surface, skipping hook"
      exit 0
    }

    # Try to show diff for the edited file
    FILE_DIFF=""

    # 1. Try git diff (works for files in git repos)
    if ! FILE_DIFF=$(git -C "$(dirname "$FILE_PATH")" diff -- "$FILE_PATH" 2>&1); then
      log "WARN: git diff failed for $FILE_PATH: $FILE_DIFF"
      FILE_DIFF=""
    fi

    # 2. For Edit/MultiEdit outside git, construct diff from old_string/new_string
    if [[ -z "$FILE_DIFF" && "$TOOL_NAME" =~ ^(Edit|MultiEdit)$ ]]; then
      OLD_STRING=$(echo "$HOOK_INPUT" | jq -r '.tool_input.old_string // empty')
      NEW_STRING=$(echo "$HOOK_INPUT" | jq -r '.tool_input.new_string // empty')
      if [[ -n "$OLD_STRING" || -n "$NEW_STRING" ]]; then
        FILE_DIFF=$(diff -u \
          --label "a/$(basename "$FILE_PATH")" \
          --label "b/$(basename "$FILE_PATH")" \
          <(printf '%s\n' "$OLD_STRING") \
          <(printf '%s\n' "$NEW_STRING") 2>/dev/null || true)
      fi
    fi

    if [[ -n "$FILE_DIFF" ]]; then
      echo "$FILE_DIFF" > "$DIFF_FILE"
      show_diff_in_pane "$SURFACE_ID" "$FILE_DIFF" "$FILE_PATH"
      log "DIFF: $FILE_PATH (tool=$TOOL_NAME) -> delta side-by-side"
    else
      # No diff (new file via Write, or no changes) - open the file directly
      open_in_helix "$SURFACE_ID" "${FILE_PATH}"
      log "OPEN: $FILE_PATH (tool=$TOOL_NAME, no diff available)"
    fi
    ;;
  stop)
    CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty')
    if [[ -z "$CWD" ]]; then
      log "SKIP: no cwd in hook input"
      exit 0
    fi

    DIFF_OUTPUT=""
    if ! DIFF_OUTPUT=$(git -C "$CWD" diff HEAD 2>&1); then
      log "WARN: git diff failed in $CWD: $DIFF_OUTPUT"
      exit 0
    fi

    if [[ -z "$DIFF_OUTPUT" ]]; then
      log "SKIP: no git changes at stop"
      exit 0
    fi

    echo "$DIFF_OUTPUT" > "$DIFF_FILE"

    SURFACE_ID=$(get_helix_surface_id) || {
      log "ERROR: Could not detect helix surface, skipping hook"
      exit 0
    }
    show_diff_in_pane "$SURFACE_ID" "$DIFF_OUTPUT" ""
    log "DIFF: stop diff -> delta side-by-side"
    ;;
  *)
    log "ERROR: Unknown mode: $MODE"
    exit 1
    ;;
esac
