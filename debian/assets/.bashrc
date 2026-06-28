# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=${HISTSIZE:-10000}
HISTFILESIZE=${HISTFILESIZE:-20000}
shopt -s histappend

# Check terminal size after each command.
shopt -s checkwinsize

# Alias definitions.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Prompt settings
if [ -t 1 ]; then
  c_cwd='\[\033[01;32m\]'   # bold green
  c_git='\[\033[01;34m\]'   # bold blue
  c_reset='\[\033[00m\]'
else
  c_cwd=''
  c_git=''
  c_reset=''
fi

PS1="${c_cwd}\w${c_reset} (${c_git}"'$(__git_ps1 "%s"'"${c_reset})) \$ "
