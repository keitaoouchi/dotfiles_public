#aliases
alias la="ls -la"
alias ll="ls -l"
alias pa="ps -alx"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -p"
alias ..="cd .."
alias ...="cd ../.."
alias zmv="noglob zmv -W"
# All warfare is based on deception
alias vim="atom"
if [ -d $HOME/.ssh/conf.d ]; then
  alias ssh="cat ~/.ssh/conf.d/*.conf > ~/.ssh/config;ssh"
  alias sftp="cat ~/.ssh/conf.d/*.conf > ~/.ssh/config;sftp"
  alias scp="cat ~/.ssh/conf.d/*.conf > ~/.ssh/config;scp"
  alias git="cat ~/.ssh/conf.d/*.conf > ~/.ssh/config;git"
fi
