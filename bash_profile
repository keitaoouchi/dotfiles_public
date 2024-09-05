# aliasの設定
source $HOME/.dotfiles_public/alias.sh

# secrectの設定
if [ -f $HOME/.dotfiles_private/secret.sh ]; then
  $HOME/.dotfiles_private/secret.sh
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
if [ -f $HOME/.asdf/bin/asdf ]; then
  PATH=$PATH:$HOME/.asdf/bin
  . $HOME/.asdf/asdf.sh
  . $HOME/.asdf/completions/asdf.bash
fi

# starship
if [ -x "$(command -v starship)" ]; then
  eval "$(starship init bash)"
  starship preset no-nerd-font -o ~/.config/starship.toml
fi
