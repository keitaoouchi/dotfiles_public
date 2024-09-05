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
alias vim="code"
# 千里之行，始于足下
if which git-switch-trainer >/dev/null 2>&1 ; then
  alias git="git-switch-trainer"
fi
