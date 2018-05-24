#
# User configuration sourced by interactive shells
#
# INTERNAL UTILITY FUNCTIONS {{{1

# Returns whether the given command is executable or aliased.
_has() {
  return $( whence $1 >/dev/null )
}

# Returns whether the given statement executed cleanly. Try to avoid this
# because this slows down shell loading.
_try() {
  return $( eval $* >/dev/null 2>&1 )
}

# Returns whether the current host type is what we think it is. (HOSTTYPE is
# set later.)
_is() {
  return $( [ "$HOSTTYPE" = "$1" ] )
}

# Returns whether out terminal supports color.
_color() {
  return $( [ -z "$INSIDE_EMACS" ] )
}

# Source zim
if [[ -s ${ZDOTDIR:-${HOME}}/.zim/init.zsh ]]; then
  source ${ZDOTDIR:-${HOME}}/.zim/init.zsh
fi

#export ZPLUG_HOME=/usr/local/opt/zplug
#source $ZPLUG_HOME/init.zsh

# Supports oh-my-zsh plugins and the like
#zplug "plugins/git",   from:oh-my-zsh

# Also prezto
#zplug "modules/prompt", from:prezto

# Load if "if" tag returns true
#zplug "lib/clipboard", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"

#zplug "modules/directory", from:zimfw
#zplug "modules/environment", from:zimfw
#zplug "modules/git", from:zimfw
#zplug "modules/git-info", from:zimfw
#zplug "modules/history", from:zimfw
#zplug "modules/input", from:zimfw
#zplug "modules/utility", from:zimfw
#zplug "modules/meta", from:zimfw
#zplug "modules/custom", from:zimfw
#zplug "modules/prompt", from:zimfw
#zplug "modules/completion", from:zimfw

# Load theme file
#zplug 'dracula/zsh', as:theme

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "/Users/jonathan.hicks/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

alias ls="ls -h"
alias ll="ls -l"
alias la="ls -a"
alias b="bundle"
alias be="bundle exec"
alias gts="git tag --sort version:refname"
# alias fig to docker-compose because that's how the cool kids roll
alias fig="docker-compose"

# other useful aliases
alias clear_pids="rm ~/projects/*/tmp/pids/server.pid"
alias restart_docker="docker-compose kill; clear_pids; docker-compose up -d; clear; docker-compose ps"

#alias restart_dock=osascript -e 'quit application "Dock"'

export JAVA_HOME=$(/usr/libexec/java_home)
export SPARK_HOME="$HOME/lib/spark-2.0.2-bin-hadoop2.4"

export PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$HOME/.rbenv/bin:$PATH"

bindkey -M vicmd "k" history-substring-search-up
bindkey -M vicmd "j" history-substring-search-down

eval "$(rbenv init -)"
eval "$(pyenv init -)"

# fzf via Homebrew
if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# fzf via local installation
if [ -e ~/.fzf ]; then
  _append_to_path ~/.fzf/bin
  source ~/.fzf/shell/key-bindings.zsh
  source ~/.fzf/shell/completion.zsh
fi

# fzf + ag configuration
if _has fzf && _has ag; then
  export FZF_DEFAULT_COMMAND='ag --nocolor -g ""'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='
  --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
  --color info:108,prompt:109,spinner:108,pointer:168,marker:168
  '
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# This is to automatically run 'nvm use' in dir that contain .nvmrc
# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
