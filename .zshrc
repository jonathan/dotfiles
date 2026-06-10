if [ -e ~/.bootstrap_rc ]; then
  source /Users/jonathan.hicks/.bootstrap_rc
fi
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/jonathan.hicks/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="gitster"
ZSH_THEME="dracula"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git git-prompt zsh-autosuggestions zcolors colorize docker kubectl)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='nvim'
# else
#   export EDITOR='vim'
# fi
export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="nvim ~/.zshrc"
# alias ohmyzsh="nvim ~/.oh-my-zsh"

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -v

# Prompt for spelling correction of commands.
setopt CORRECT

# Customize spelling correction prompt.
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

#
# zsh-syntax-highlighting
#

# source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters/
# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=10'

#
# zsh-history-substring-search
#

source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Bind up and down keys
zmodload -F zsh/terminfo +p:terminfo
if [[ -n ${terminfo[kcuu1]} && -n ${terminfo[kcud1]} ]]; then
  bindkey ${terminfo[kcuu1]} history-substring-search-up
  bindkey ${terminfo[kcud1]} history-substring-search-down
fi

bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# zcolor config
# source ~/.oh-my-zsh/custom/plugins//zcolors/zcolors.plugin.zsh
# source ~/.zcolors

ZSH_COLORIZE_TOOL=chroma

# ------------------------------
# Post-init module configuration
# ------------------------------

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
#zstyle :compinstall filename "/Users/jonathan.hicks/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

# eza (modern ls) — falls back to coreutils ls if eza isn't installed
if command -v eza >/dev/null; then
  alias ls="eza --group-directories-first --icons --git"
  alias ll="eza -lFh --group-directories-first --icons --git"
  alias la="eza -a --group-directories-first --icons --git"
  alias lt="eza --tree --level=2 --icons"
else
  alias ls="ls -hG"
  alias ll="ls -lFh"
  alias la="ls -ah"
fi
alias gts="git tag --sort version:refname"
alias gbc="git checkout -b"
alias kconnect="kinit jonathan.hicks@QA.LOCAL"
alias vi='nvim'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias zshrc='${=EDITOR} ~/.zshrc'

alias du='du -h'

# Use bat for any help commands
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'

#alias restart_dock=osascript -e 'quit application "Dock"'

# Compiler flags
# NOTE: legacy Intel-Homebrew paths (/usr/local). On Apple Silicon these resolve
# to nothing; uncomment and repoint to /opt/homebrew if you build against them.
# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib -L/opt/homebrew/opt/libffi/lib -L/opt/homebrew/opt/openssl/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include -I/opt/homebrew/opt/openssl/include"
# export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig"

# export LLVM_HOME="/usr/local/opt/llvm"
# export ERLANG_MAN="/usr/local/opt/erlang/lib/erlang/man"
# export TERRAFORM_HOME="/usr/local/opt/terraform@0.12"
export DOCKER_HOST="unix:///Users/jonathan.hicks/.docker/run/docker.sock"

# Store sensative env vars here
if [ -e ~/.env_vars.zsh ]; then
  source ~/.env_vars.zsh
fi

export GUILE_TLS_CERTIFICATE_DIRECTORY="/usr/local/etc/gnutls/"

export PATH="/usr/local/bin:/usr/local/sbin:$HOME/bin:/Applications/Docker.app/Contents/Resources/bin/:$HOME/.local/bin:$HOME/.cargo/bin/:$PATH"
#export PATH="/usr/local/bin:$HOME/bin:$LLVM_HOME/bin:$HOME/.rbenv/bin:$PATH"
# export MANPATH="$ERLANG_MAN:$MANPATH"

# export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# fzf — key bindings + completion (fzf >= 0.48 ships `fzf --zsh`)
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi

# Use fd for fzf's file/dir search when available (respects .gitignore, faster)
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

# zoxide — smarter cd (z <partial-dir-name>)
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v kubectl >/dev/null; then source <(kubectl completion zsh); fi

# Node version management is handled by Volta (automatic per-project switching,
# no shell hook). The previous nvm setup + load-nvmrc chpwd hook was removed —
# it was slow and redundant with Volta.
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
# export SSH_AUTH_SOCK="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.jonathanhicks.omp.json)"
fi

# NODE_EXTRA_CA_CERTS — devbar-managed bundle (this is the effective value)
# devbar-managed-start
export NODE_EXTRA_CA_CERTS="$HOME/.devbar/certs/corporate-ca-bundle.pem"
# devbar-managed-end

export GOPATH=$HOME/go

# Added by get-aspire-cli.sh
export PATH="$HOME/.aspire/bin:$PATH"
