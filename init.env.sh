# nodenv初期化(homebrewで導入)
if which nodenv >/dev/null 2>&1; then 
  eval "$(nodenv init -)"
fi

# rbenv初期化(homebrewで導入)
if which rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go

if which pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  # poetry
  PATH=$HOME/.poetry/bin:$PATH
fi
