# nodenv初期化(homebrewで導入)
[[ `which nodenv 2> /dev/null` ]] && eval "$(nodenv init -)"

# rbenv初期化(homebrewで導入)
[[ `which rbenv 2> /dev/null` ]] && eval "$(rbenv init -)"

if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go

if [ `which pyenv 2> /dev/null` ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  # poetry
  PATH=$HOME/.poetry/bin:$PATH
fi
