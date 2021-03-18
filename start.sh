ln -s $HOME/dotfiles_private/.ssh $HOME/.ssh
ln -s $HOME/dotfiles_public/zshrc $HOME/.zshrc
ln -s $HOME/dotfiles_public/vimrc $HOME/.vimrc
ln -s $HOME/dotfiles_public/gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles_public/gitignore_global $HOME/.gitignore_global

brew install \
    direnv git jq openssl pyenv rbenv nodenv \
    zsh-completions zsh-syntax-highlighting \
    poetry
