# nodenv初期化(homebrewで導入)
[[ `which nodenv 2> /dev/null` ]] && eval "$(nodenv init -)"
# pyenv初期化(homebrewで導入)
[[ `which pyenv 2> /dev/null` ]] && eval "$(pyenv init -)"
# poetry
PATH=$HOME/.poetry/bin:$PATH
# rbenv初期化(homebrewで導入)
[[ `which rbenv 2> /dev/null` ]] && eval "$(rbenv init -)"

if [ ! -d $HOME/.go ]; then
  mkdir $HOME/.go
fi
export GOPATH=$HOME/.go