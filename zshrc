# aliases
source $HOME/.alias.sh

# zmv (zsh built-in)
autoload -U zmv

# 1Password secrets
export GITHUB_TOKEN="$(op read op://Private/secrets/github_token 2>/dev/null)"

# macOS / Homebrew
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH

# go
[[ ! -d $HOME/.go ]] && mkdir $HOME/.go
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

# rust
[[ -d $HOME/.cargo/bin ]] && export PATH=$PATH:$HOME/.cargo/bin

# starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# mcfly
if command -v mcfly &>/dev/null; then
  eval "$(mcfly init zsh)"
fi

# zsh completions
FPATH=/opt/homebrew/share/zsh-completions:$FPATH
autoload -Uz compinit
compinit

# mise
eval "$($HOME/.local/bin/mise activate zsh)"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
