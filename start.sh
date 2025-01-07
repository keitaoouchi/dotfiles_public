rm $HOME/.gitconfig $HOME/.gitignore_global $HOME/.tmux.conf $HOME/.asdfrc $HOME/.bash_profile
ln -s $HOME/.dotfiles_public/gitconfig $HOME/.gitconfig
ln -s $HOME/.dotfiles_public/gitignore_global $HOME/.gitignore_global
ln -s $HOME/.dotfiles_public/tmux.conf $HOME/.tmux.conf
ln -s $HOME/.dotfiles_public/asdfrc $HOME/.asdfrc
ln -s $HOME/.dotfiles_public/bash_profile $HOME/.bash_profile

# If brew installed
if [ -x "$(command -v brew)" ]; then
  brew install curl direnv git jq openssl tmux
  # nerd font
  brew install font-hack-nerd-font
# If apt available
elif [ -x "$(command -v apt)" ]; then
  sudo apt update -y
  sudo apt install -y direnv git jq openssl tmux
  # nerd font
  FONT=FiraCode.tar.xz
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/$FONT -o ~/.local/share/fonts/$FONT \
    && cd ~/.local/share/fonts \
    && tar -xf $FONT \
    && rm -f $FONT \
    && fc-cache -fv

fi

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf
PATH=$PATH:$HOME/.asdf/bin

asdf plugin add nodejs
asdf plugin add ruby
asdf plugin add python
asdf plugin add golang
