ln -s $HOME/dotfiles_private/.ssh $HOME/.ssh
ln -s $HOME/dotfiles_public/zshrc $HOME/.zshrc
ln -s $HOME/dotfiles_public/vimrc $HOME/.vimrc
ln -s $HOME/dotfiles_public/gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles_public/gitignore_global $HOME/.gitignore_global
ln -s $HOME/dotfiles_public/tmux.conf $HOME/.tmux.conf
ln -s $HOME/dotfiles_public/asdfrc $HOME/.asdfrc

brew install \
    direnv git jq openssl \
    zsh-completions zsh-syntax-highlighting \
    gpg gawk asdf \
    tmux

exec $SHELL

asdf plugin add nodejs
asdf plugin add ruby
asdf plugin add python
asdf plugin add golang
