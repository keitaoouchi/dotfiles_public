# nodenv初期化(homebrewで導入)
if which nodenv >/dev/null 2>&1; then 
  eval "$(nodenv init -)"
fi

# rbenv初期化(homebrewで導入)
if which rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# go
if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go

# python
if which pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  # poetry
  export PATH=$HOME/.poetry/bin:$PATH
fi

# java & android
export JAVA_HOME=`/usr/libexec/java_home`
if [ -d $HOME/Library/Android/sdk/platform-tools ]; then
  export PATH=$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/tools:$PATH
fi

# direnv
eval "$(direnv hook zsh)"
