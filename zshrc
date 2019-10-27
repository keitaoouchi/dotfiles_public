# xxenv
source "$HOME/dotfiles_public/init.vm.sh"

# aliasの設定
source $HOME/dotfiles_public/alias.sh

# local bin directory
if [ ! -d $HOME/.bin ]; then
  mkdir $HOME/.bin
fi

HOMEBIN=$HOME/.bin

# assemble PATH
PATH=$HOMEBIN:/usr/local/bin:/usr/local/sbin:$PATH

# PATHをexport
export PATH

if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go

if [ -f $HOME/dotfiles_private/secret.sh ]; then
  $HOME/dotfiles_private/secret.sh
fi
