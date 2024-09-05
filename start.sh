ln -s $HOME/.dotfiles_public/gitconfig $HOME/.gitconfig
ln -s $HOME/.dotfiles_public/gitignore_global $HOME/.gitignore_global
ln -s $HOME/.dotfiles_public/tmux.conf $HOME/.tmux.conf
ln -s $HOME/.dotfiles_public/asdfrc $HOME/.asdfrc
ln -s $HOME/.dotfiles_public/bash_profile $HOME/.bash_profile

# If brew installed
if [ -x "$(command -v brew)" ]; then
  brew install \
    curl \
    direnv \
    git \
    jq \ 
    openssl \
    asdf \
    tmux
# If apt available
elif [ -x "$(command -v apt)" ]; then
  sudo apt update -y
  sudo apt install -y \
    direnv \
    git \
    jq \
    openssl \
    tmux

  # Install asdf
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf
  PATH=$PATH:$HOME/.asdf/bin
fi

exec $SHELL

asdf plugin add nodejs
asdf plugin add ruby
asdf plugin add python
asdf plugin add golang
