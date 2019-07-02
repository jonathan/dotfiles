export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh
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

#alias restart_dock=osascript -e 'quit application "Dock"'

# Compiler flags
export LDFLAGS="-L/usr/local/opt/llvm/lib -L/usr/local/opt/libffi/lib -L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include -I/usr/local/opt/openssl/include"

export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"

export JAVA_HOME=$(/usr/libexec/java_home)
export GRAAL_HOME="$HOME/tools/graalvm-ce-19.0.0/Contents/Home"
export LLVM_HOME="/usr/local/opt/llvm"

export SOURCEKIT_TOOLCHAIN_PATH="/Library/Developer/Toolchains/swift-latest.xctoolchain"

# Store sensative env vars here
if [ -e ~/.env_vars.zsh ]; then
  source ~/.env_vars.zsh
fi

export PATH="/usr/local/bin:$HOME/bin:$LLVM_HOME/bin:$GRAAL_HOME/bin:$HOME/.rbenv/bin:$PATH"
#export PATH="/usr/local/bin:$HOME/bin:$LLVM_HOME/bin:$HOME/.rbenv/bin:$PATH"

bindkey -M vicmd "k" history-substring-search-up
bindkey -M vicmd "j" history-substring-search-down

eval "$(rbenv init -)"

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
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/bash_completion" ] && \. "/usr/local/opt/nvm/bash_completion"  # This loads nvm bash_completion

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
