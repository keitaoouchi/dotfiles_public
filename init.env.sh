# go
if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go

# java & android
export JAVA_HOME=`/usr/libexec/java_home`
if [ -d $HOME/Library/Android/sdk/platform-tools ]; then
  export PATH=$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/tools:$PATH
fi

# GO
mkdir -p $HOME/.go
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

# direnv
export EDITOR=code
eval "$(direnv hook zsh)"

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh
