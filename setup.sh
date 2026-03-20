#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Dotfiles setup: $DOTFILES_DIR"

# ---- Prerequisites -------------------------------------------------------

if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew not found. Install from https://brew.sh"
  exit 1
fi

# ---- Symlinks ------------------------------------------------------------

link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/.$1"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -f "$dst" ]]; then
    mv "$dst" "${dst}.bak"
    echo "  Backed up: ${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  Linked: $dst -> $src"
}

echo "==> Creating symlinks..."
link zshrc
link alias.sh
link gitconfig
link gitignore_global
link tmux.conf

# config/my.cnf
mkdir -p "$HOME/.config"
if [[ -L "$HOME/.config/my.cnf" ]]; then
  rm "$HOME/.config/my.cnf"
fi
ln -sf "$DOTFILES_DIR/config/my.cnf" "$HOME/.config/my.cnf"
echo "  Linked: ~/.config/my.cnf"

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

# ---- 1Password: generate ~/.gitconfig.local ------------------------------

if command -v op &>/dev/null && op account list &>/dev/null; then
  echo "==> Generating ~/.gitconfig.local from 1Password..."
  cat > "$HOME/.gitconfig.local" <<EOF
[user]
  name = $(op read "op://Private/dotfiles/git_name")
  email = $(op read "op://Private/dotfiles/git_email")
  signingkey = $(op read "op://Private/dotfiles/git_signing_key")
EOF
  echo "  Done."
else
  echo "Warning: 1Password CLI not available or not signed in."
  echo "  Run 'eval \$(op signin)' then re-run this script,"
  echo "  or create ~/.gitconfig.local manually:"
  echo '  [user]'
  echo '    name = Your Name'
  echo '    email = your@email.com'
  echo '    signingkey = ssh-ed25519 ...'
fi

# ---- Packages ------------------------------------------------------------

echo "==> Installing Homebrew packages..."
brew install \
  curl git jq openssl tmux \
  zsh-completions \
  bat difftastic eza fd fzf gh mcfly ripgrep \
  claude-code codex gh zellix yazi helix powerlevel10k \
  pyright gopls terraform-ls

echo "==> Installing LSP servers (npm)..."
npm install -g typescript-language-server typescript vscode-langservers-extracted

# ---- Starship ------------------------------------------------------------

echo "==> Installing Starship..."
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
starship preset pure-preset -o "$HOME/.config/starship.toml"

# ---- mise ----------------------------------------------------------------

echo "==> Installing mise..."
if ! command -v mise &>/dev/null; then
  curl https://mise.run | sh
fi

# ---- Fonts ---------------------------------------------------------------

echo "==> Installing Nerd Fonts..."
if ! brew list font-hack-nerd-font &>/dev/null; then
  brew install font-hack-nerd-font
fi

# ---- Default shell -------------------------------------------------------

echo "==> Configuring default shell..."
if [[ "$SHELL" != "/bin/zsh" ]]; then
  if ! grep -q "^/bin/zsh$" /etc/shells; then
    echo "/bin/zsh" | sudo tee -a /etc/shells
  fi
  chsh -s /bin/zsh
  echo "  Default shellhanged to zsh. Restart your terminal."
else
  echo "  Already using zsh."
fi

echo ""
echo "Done! Open a new terminal to apply changes."
