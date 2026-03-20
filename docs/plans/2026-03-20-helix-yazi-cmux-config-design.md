# Helix / Yazi / cmux Configuration Design

## Context

User is transitioning from IntelliJ to a terminal-first workflow centered on Claude Code. AI-driven development is the primary activity; manual coding is secondary. The three tools complement Claude Code:

- **Helix**: File/diff viewer, not a primary editor. LSP for navigation (Go to Definition, symbol search), file picker, global grep.
- **Yazi**: Project Tree replacement for IntelliJ. Always-visible file structure overview. Selecting a file opens it in Helix.
- **cmux**: Manages the 3-pane layout.

## Layout

```
┌──────────────┬──────────────┬────────────┐
│ Claude Code  │    Helix     │    Yazi    │
│  (left pane) │ (center pane)│(right pane)│
└──────────────┴──────────────┴────────────┘
```

## Helix Configuration

### config/helix/config.toml

- Theme: `catppuccin_mocha`
- Line numbers (relative for quick jumps)
- Cursorline highlight
- Scroll offset (5 lines)
- File picker: show hidden files, exclude `.git/`, `node_modules/`, `__pycache__/`, `.venv/`
- Auto-save: off (viewer usage)
- Soft wrap: enabled (no horizontal scrolling)
- Gutters: diagnostics, line-numbers, spacer, diff
- Mouse: enabled (terminal clicking)

### config/helix/languages.toml

LSP servers for the user's stack:
- Python: `pyright` (better type inference than pylsp)
- Go: `gopls`
- TypeScript/TSX/React: `typescript-language-server`
- Terraform: `terraform-ls`
- HTML/htmx: `vscode-html-language-server`

LSP binaries installed via setup.sh (brew/npm/pip as appropriate).

## Yazi Configuration

### config/yazi/yazi.toml

- Sort: alphabetical, directories first
- Show hidden files: yes
- Preview pane: enabled (file content preview in right column)
- Ratio: `[1, 2, 3]` — more space for preview

### config/yazi/keymap.toml

- `Enter` on a file: run `yazi-open-in-helix.sh` to send `:open` to Helix pane via cmux
- Default navigation otherwise preserved

### config/yazi/theme.toml

- Minimal customization, aligned with Helix catppuccin theme

## Scripts

### bin/yazi-open-in-helix.sh (new)

Called by yazi keymap. Receives file path, uses cmux to send `:open <path>` to the Helix surface. Detects Helix surface similarly to the bridge script (cache or auto-detect the center pane).

### bin/claude-helix-bridge.sh (existing, extend)

Extend 2-pane logic to 3-pane:
- Pane detection now identifies center (Helix) and right (Yazi) panes
- On hook trigger, still sends diffs/files to the center (Helix) pane
- No direct interaction with yazi pane from the bridge

## setup.sh Changes

### New symlinks

```
config/helix/ → ~/.config/helix/
config/yazi/  → ~/.config/yazi/
```

Symlink the directories (not individual files) so new config files are automatically picked up.

### New packages

```bash
# LSP servers
brew install pyright gopls terraform-ls
npm install -g typescript-language-server typescript vscode-langservers-extracted
```

## File Structure

```
config/
  my.cnf              (existing)
  helix/
    config.toml
    languages.toml
  yazi/
    yazi.toml
    keymap.toml
    theme.toml
bin/
  claude-helix-bridge.sh  (existing, extend for 3-pane)
  yazi-open-in-helix.sh   (new)
setup.sh                  (add symlinks + LSP installs)
```
