if [ -e ~/.bootstrap_rc ]; then
  source ~/.bootstrap_rc
fi

# ============================================================================
# zinit — fast plugin manager (replaced the oh-my-zsh framework).
# The oh-my-zsh *framework* was a ~216ms fixed startup cost (measured with
# `zmodload zsh/zprof`); zinit loads the same features with most plugins
# deferred (`wait` = after first prompt), getting startup to ~0.10s.
# We still pull a couple of individual plugins/libs FROM the oh-my-zsh repo
# via `snippet OMZ::...` — that's just sourcing one file, not the framework.
# ============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
  print -P "%F{33}Installing zinit...%f"
  command mkdir -p "$(dirname $ZINIT_HOME)"
  command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- Editor / shell options (set early so they apply regardless of defers) ---
export EDITOR='nvim'

# History
setopt HIST_IGNORE_ALL_DUPS
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

# vi keybindings + spelling correction
bindkey -v
setopt CORRECT
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# --- Completion system -------------------------------------------------------
# Initialize once, from the cached dump, skipping the slow security audit.
# (zinit's `blockf` keeps plugins from polluting fpath before this runs.)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit            # dump older than 24h -> rebuild
else
  compinit -C         # fresh enough -> reuse cache (fast path)
fi

# --- Plugins (turbo / deferred where safe) ----------------------------------
# git aliases + helpers from oh-my-zsh's git plugin (the main thing used daily).
zinit wait lucid for OMZ::plugins/git/git.plugin.zsh

# docker / kubectl completions — loaded after first prompt, only the completion
# defs (not the whole omz plugin framework).
zinit wait lucid as'completion' for \
  OMZ::plugins/docker/completions/_docker
zinit wait lucid for \
  atload'zicompinit; zicdreplay' \
  OMZ::plugins/kubectl/kubectl.plugin.zsh

# Fish-like UX, all deferred until after the first prompt is drawn:
#   autosuggestions, then syntax-highlighting, then history-substring-search.
# Order matters: syntax-highlighting must load before history-substring-search.
zinit wait lucid for \
  atload'_zsh_autosuggest_start' \
      zsh-users/zsh-autosuggestions \
  atinit'ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)' \
      zdharma-continuum/fast-syntax-highlighting \
  atload'
    bindkey "^[[A" history-substring-search-up;   bindkey "^[[B" history-substring-search-down
    bindkey "^P"   history-substring-search-up;   bindkey "^N"   history-substring-search-down
    bindkey -M vicmd "k" history-substring-search-up; bindkey -M vicmd "j" history-substring-search-down
  ' \
      zsh-users/zsh-history-substring-search

# ============================================================================
# Everything below here is unchanged from the previous (oh-my-zsh) .zshrc —
# env vars, PATH, aliases, OS-detection, fzf/zoxide/oh-my-posh init.
# ============================================================================

ZSH_COLORIZE_TOOL=chroma

# Debian/Ubuntu rename these binaries to avoid clashes. Alias them back to the
# names the rest of this config (and muscle memory) expects.
if ! command -v fd >/dev/null && command -v fdfind >/dev/null; then
  alias fd='fdfind'
fi
if ! command -v bat >/dev/null && command -v batcat >/dev/null; then
  alias bat='batcat'
fi

# eza (modern ls) — falls back to coreutils ls if eza isn't installed
if command -v eza >/dev/null; then
  alias ls="eza --group-directories-first --icons --git"
  alias ll="eza -lFh --group-directories-first --icons --git"
  alias la="eza -a --group-directories-first --icons --git"
  alias lt="eza --tree --level=2 --icons"
else
  # Color flag differs: BSD/macOS uses -G, GNU/Linux uses --color=auto
  if ls --color=auto >/dev/null 2>&1; then
    alias ls="ls -h --color=auto"        # GNU coreutils (Linux)
  else
    alias ls="ls -hG"                    # BSD ls (macOS)
  fi
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

# macOS Docker Desktop puts its socket under ~/.docker. On Linux the default
# /var/run/docker.sock is used automatically, so DOCKER_HOST is left unset.
if [[ "$OSTYPE" == darwin* ]] && [ -S "$HOME/.docker/run/docker.sock" ]; then
  export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
fi

# Store sensative env vars here
if [ -e ~/.env_vars.zsh ]; then
  source ~/.env_vars.zsh
fi

# GnuTLS cert dir — path differs by OS; only export if it exists.
for _gnutls in /opt/homebrew/etc/gnutls /usr/local/etc/gnutls /etc/gnutls; do
  [ -d "$_gnutls" ] && export GUILE_TLS_CERTIFICATE_DIRECTORY="$_gnutls/" && break
done
unset _gnutls

# Cross-platform PATH: personal bins first, then language toolchains.
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
# macOS-only: Docker Desktop CLI tools
if [[ "$OSTYPE" == darwin* ]] && [ -d "/Applications/Docker.app/Contents/Resources/bin" ]; then
  export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi
# export MANPATH="$ERLANG_MAN:$MANPATH"

# export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# fzf — key bindings + completion (fzf >= 0.48 ships `fzf --zsh`)
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi

# Use fd for fzf's file/dir search when available (respects .gitignore, faster).
# Resolve the real binary name (fd on mac/Homebrew, fdfind on Debian/Ubuntu).
_fd_bin=""
if command -v fd >/dev/null; then
  _fd_bin=fd
elif command -v fdfind >/dev/null; then
  _fd_bin=fdfind
fi
if [ -n "$_fd_bin" ]; then
  export FZF_DEFAULT_COMMAND="$_fd_bin --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_fd_bin --type d --hidden --follow --exclude .git"
fi
unset _fd_bin

export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

# zoxide — smarter cd (z <partial-dir-name>)
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

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
