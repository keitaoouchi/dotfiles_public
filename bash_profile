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

# direnv
export EDITOR=code
eval "$(direnv hook bash)"

# asdf
if [ -d $HOME/.asdf/ ]; then
  PATH=$HOME/.asdf/shims:$PATH
  . $(brew --prefix asdf)/libexec/asdf.sh
fi

# java
if [ -f ~/.asdf/plugins/java/set-java-home.bash ]; then
  source ~/.asdf/plugins/java/set-java-home.bash
fi

# starship
if [ -x "$(command -v starship)" ]; then
  eval "$(starship init bash)"
  starship preset pastel-powerline -o ~/.config/starship.toml
fi

# bash-completion(mac)
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
