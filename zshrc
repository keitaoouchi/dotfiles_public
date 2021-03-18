# homebrew for arm64
typeset -U path PATH
path=(
	/opt/homebrew/bin(N-/)
	/usr/local/bin(N-/)
  $HOME/bin(N-/)
	$path
)

# PATHをexport
export PATH

# xxenv
source "$HOME/dotfiles_public/init.env.sh"

# aliasの設定
source $HOME/dotfiles_public/alias.sh

if [ -f $HOME/dotfiles_private/secret.sh ]; then
  $HOME/dotfiles_private/secret.sh
fi

# enable zsh plugins

source "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh"
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
