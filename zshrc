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

setopt correct
autoload -Uz compinit && compinit
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' menu select=2

#https://nicedoc.io/sindresorhus/pure#getting-started
if [ ! -d $HOME/.zsh/pure ]; then
  mkdir -p "$HOME/.zsh"
  git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
fi
fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/keeeita/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/keeeita/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/keeeita/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/keeeita/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
