#!/usr/bin/env bash

# Check if running as root (Linux only)
if [ "$(uname)" != 'Darwin' ] && [ "$(id -u)" -ne 0 ]; then
  echo "Switching to root user..."
  exec sudo su -c "bash $0"
fi

# Create symlinks as original user
ORIGINAL_USER=$(who am i | awk '{print $1}')
if [ -n "$ORIGINAL_USER" ]; then
  sudo -u $ORIGINAL_USER bash -c "
    rm -f \$HOME/.gitconfig \$HOME/.gitignore_global \$HOME/.tmux.conf \$HOME/.bash_profile
    for file in gitconfig gitignore_global tmux.conf bash_profile; do
      if [ ! -f \"\$HOME/.dotfiles_public/\$file\" ]; then
        echo \"Warning: Source file \$HOME/.dotfiles_public/\$file not found\"
        continue
      fi
      ln -s \"\$HOME/.dotfiles_public/\$file\" \"\$HOME/.\$file\"
    done
  "
fi

# If brew installed
if [ -x "$(command -v brew)" ]; then
  brew install curl git jq openssl tmux bash-completion@2
  # nerd font
  brew install font-hack-nerd-font
# If apt available
elif [ -x "$(command -v apt)" ]; then
  apt update -y
  apt install -y git jq openssl tmux bash-completion curl xz-utils
  # nerd font
  FONT_NAME="FiraCode"
  FONT_FILE="${FONT_NAME}.tar.xz"
  FONT_DIR="$HOME/.local/share/fonts"
  FONT_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r .tag_name)
  mkdir -p "$FONT_DIR"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_FILE}" -o "${FONT_DIR}/${FONT_FILE}" \
    && cd ~/.local/share/fonts \
    && tar -xf "$FONT_FILE" \
    && rm -f "$FONT_FILE" \
    && fc-cache -fv
fi

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Install mise
curl https://mise.run | sh
eval "$($HOME/.local/bin/mise activate bash)"
mise use -g usage

if [ "$(uname)" == 'Darwin' ]; then
  COMPLETION_DIR="/opt/homebrew/etc/bash_completion.d"
else
  COMPLETION_DIR="/etc/bash_completion.d"
fi
mkdir -p "$COMPLETION_DIR"
mise completion bash --include-bash-completion-lib | tee "$COMPLETION_DIR/mise" > /dev/null
