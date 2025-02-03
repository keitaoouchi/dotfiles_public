# aliasの設定
source $HOME/.dotfiles_public/alias.sh

# secrectの設定
if [ -f $HOME/.dotfiles_private/secret.sh ]; then
  $HOME/.dotfiles_private/secret.sh
fi

# if mac
if [ "$(uname)" == 'Darwin' ]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
  export PATH=/opt/homebrew/bin:$PATH
  java_macos_integration_enable=yes
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# go
if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

# rust
if [ -d .cargo/bin ]; then
  export PATH=$PATH:$HOME/.cargo/bin
fi

# starship
if [ -x "$(command -v starship)" ]; then
  eval "$(starship init bash)"
  starship preset pastel-powerline -o ~/.config/starship.toml
fi

if [ "$(uname)" == 'Darwin' ]; then
  [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
elif [ "$(uname)" == 'Linux' ]; then
  [[ -r "/usr/share/bash-completion/bash_completion" ]] && . "/usr/share/bash-completion/bash_completion"
fi

# mise
# https://mise.jdx.dev/getting-started.html#_2-activate-mise
eval "$($HOME/.local/bin/mise activate bash)"
