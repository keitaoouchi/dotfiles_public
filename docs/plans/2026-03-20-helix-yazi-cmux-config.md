# Helix / Yazi / cmux Config Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add dotfiles-managed configs for Helix (viewer + LSP), Yazi (project tree with open-in-helix), and update setup.sh and bridge script for 3-pane cmux layout.

**Architecture:** Config files live in `config/helix/` and `config/yazi/`, symlinked as directories to `~/.config/`. A new `bin/yazi-open-in-helix.sh` script bridges yazi file selection to Helix via cmux. The existing bridge script is updated for 3-pane awareness.

**Tech Stack:** Helix, Yazi, cmux, bash, TOML configs

---

### Task 1: Create Helix config.toml

**Files:**
- Create: `config/helix/config.toml`

**Step 1: Write the config file**

```toml
theme = "catppuccin_mocha"

[editor]
line-number = "relative"
cursorline = true
scrolloff = 5
mouse = true

[editor.soft-wrap]
enable = true

[editor.file-picker]
hidden = true

[editor.gutters]
layout = ["diagnostics", "spacer", "line-numbers", "spacer", "diff"]
```

**Step 2: Verify syntax**

Run: `hx --health`
Expected: No config parse errors

**Step 3: Commit**

```bash
git add config/helix/config.toml
git commit -m "Add helix config with viewer-oriented defaults"
```

---

### Task 2: Create Helix languages.toml

**Files:**
- Create: `config/helix/languages.toml`

**Step 1: Write the config file**

Only Python needs an override (gopls, typescript-language-server, terraform-ls, vscode-html-language-server are all built-in defaults).

```toml
[[language]]
name = "python"
language-servers = ["pyright"]
```

**Step 2: Verify LSP health**

Run: `hx --health python` and `hx --health go` and `hx --health typescript`
Expected: Shows configured language servers (some may show "not installed" if binaries aren't present yet — that's OK, setup.sh handles installation)

**Step 3: Commit**

```bash
git add config/helix/languages.toml
git commit -m "Add helix languages.toml to use pyright for Python"
```

---

### Task 3: Create Yazi config files

**Files:**
- Create: `config/yazi/yazi.toml`
- Create: `config/yazi/theme.toml`

**Step 1: Write yazi.toml**

```toml
[mgr]
ratio = [1, 4, 3]
sort_by = "natural"
sort_dir_first = true
show_hidden = true
show_symlink = true
scrolloff = 5
linemode = "size"
```

**Step 2: Write theme.toml**

```toml
# Minimal theme — yazi's default is already clean.
# Add catppuccin overrides here as desired.
```

**Step 3: Commit**

```bash
git add config/yazi/yazi.toml config/yazi/theme.toml
git commit -m "Add yazi config with IDE-like defaults"
```

---

### Task 4: Create yazi-open-in-helix.sh script

**Files:**
- Create: `bin/yazi-open-in-helix.sh`

**Step 1: Write the script**

The script receives a file path as `$1`, finds the Helix surface (center pane) via cmux, and sends `:open <path>`. It must handle 3 surface states: helix running, pager running, shell prompt.

```bash
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
```

**Step 2: Make executable**

Run: `chmod +x bin/yazi-open-in-helix.sh`

**Step 3: Commit**

```bash
git add bin/yazi-open-in-helix.sh
git commit -m "Add yazi-open-in-helix script for cmux integration"
```

---

### Task 5: Create yazi keymap.toml with open-in-helix binding

**Files:**
- Create: `config/yazi/keymap.toml`

**Step 1: Write keymap.toml**

Override Enter to open files in Helix via the bridge script. Use `prepend_keymap` to take priority over defaults. Only trigger on files (directories should still navigate normally via default behavior). Use `--orphan` so yazi doesn't block waiting for the script.

```toml
[[mgr.prepend_keymap]]
on   = "<Enter>"
run  = '''shell --orphan -- "$HOME/.dotfiles_public/bin/yazi-open-in-helix.sh %h"'''
desc = "Open file in Helix pane"
```

Note: This overrides Enter for both files and directories. To enter directories, the user uses `l` (yazi default) or `Right`. If this feels wrong, we can refine with a lua plugin later.

**Step 2: Commit**

```bash
git add config/yazi/keymap.toml
git commit -m "Add yazi keymap with Enter → open-in-helix binding"
```

---

### Task 6: Update setup.sh with new symlinks and LSP packages

**Files:**
- Modify: `setup.sh`

**Step 1: Add directory symlinks for helix and yazi after the existing config/my.cnf block (around line 43)**

```bash
# config/helix
if [[ -L "$HOME/.config/helix" ]]; then
  rm "$HOME/.config/helix"
elif [[ -d "$HOME/.config/helix" ]]; then
  mv "$HOME/.config/helix" "$HOME/.config/helix.bak"
  echo "  Backed up: ~/.config/helix.bak"
fi
ln -sf "$DOTFILES_DIR/config/helix" "$HOME/.config/helix"
echo "  Linked: ~/.config/helix"

# config/yazi
if [[ -L "$HOME/.config/yazi" ]]; then
  rm "$HOME/.config/yazi"
elif [[ -d "$HOME/.config/yazi" ]]; then
  mv "$HOME/.config/yazi" "$HOME/.config/yazi.bak"
  echo "  Backed up: ~/.config/yazi.bak"
fi
ln -sf "$DOTFILES_DIR/config/yazi" "$HOME/.config/yazi"
echo "  Linked: ~/.config/yazi"
```

**Step 2: Add LSP servers to the brew install line (line 69-73)**

Add to the existing brew install: `pyright gopls terraform-ls`

Add a new npm install line after brew:

```bash
echo "==> Installing LSP servers (npm)..."
npm install -g typescript-language-server typescript vscode-langservers-extracted
```

**Step 3: Commit**

```bash
git add setup.sh
git commit -m "Add helix/yazi symlinks and LSP server installs to setup.sh"
```

---

### Task 7: Update bridge script for 3-pane layout

**Files:**
- Modify: `bin/claude-helix-bridge.sh`

**Step 1: Update `get_helix_surface_id` to handle 3 panes**

Currently the function picks "the other pane" — with 3 panes it needs to pick the center pane (Helix), not the rightmost (Yazi). The key change is in the `other_pane` detection: instead of `head -1` (which gets the first non-self pane), we need the pane adjacent to Claude Code (the next pane, not the last one).

In the pane creation branch (`if [[ -z "$other_pane" ]]`), create 2 panes if none exist (one for Helix, one for Yazi with yazi launched).

**Step 2: Commit**

```bash
git add bin/claude-helix-bridge.sh
git commit -m "Update bridge script for 3-pane layout support"
```

---

### Task 8: Update CLAUDE.md with new file structure

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add entries for the new config directories and scripts**

Add to the File Structure section:
- `config/helix/` — Symlinked to `~/.config/helix/`. Helix editor config (viewer-oriented)
- `config/yazi/` — Symlinked to `~/.config/yazi/`. Yazi file manager config (IDE-like project tree)
- `bin/claude-helix-bridge.sh` — Claude Code hook: shows diffs/files in Helix pane via cmux
- `bin/yazi-open-in-helix.sh` — Yazi integration: opens selected file in Helix pane via cmux

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Document helix/yazi/cmux config in CLAUDE.md"
```

---

### Task 9: Verify end-to-end

**Step 1: Run setup.sh symlink section or manually create symlinks**

```bash
ln -sf ~/.dotfiles_public/config/helix ~/.config/helix
ln -sf ~/.dotfiles_public/config/yazi ~/.config/yazi
```

**Step 2: Verify Helix config loads**

Run: `hx --health`
Expected: No errors, shows catppuccin_mocha theme info

**Step 3: Verify Yazi config loads**

Run: `yazi` in a terminal
Expected: Shows hidden files, directories first, natural sort

**Step 4: Verify yazi → helix integration**

In cmux 3-pane layout, hover a file in yazi, press Enter.
Expected: File opens in the Helix pane.
