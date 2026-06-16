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

# Case-insensitive tab completion: typed lowercase also matches uppercase
# (so `cd dow<TAB>` completes `Downloads`). One-way only — a capital you type
# on purpose still matches exactly. Static zstyle, safe with the -C fast path.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

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

# 1Password CLI completion — deferred (forking `op completion zsh` costs ~60ms,
# too much for eager startup). zinit runs the atinit block after the first
# prompt; compinit has already run eagerly above, so compdef is available.
if command -v op >/dev/null; then
  zinit wait lucid as'null' for \
    atinit'eval "$(op completion zsh)"' \
    zdharma-continuum/null
fi

# Fish-like UX, all deferred until after the first prompt is drawn:
#   autosuggestions, then syntax-highlighting, then history-substring-search.
# Order matters: syntax-highlighting must load before history-substring-search.
zinit wait lucid for \
  atload'_zsh_autosuggest_start' \
      zsh-users/zsh-autosuggestions \
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

# --- HTTP / gRPC helpers ----------------------------------------------------
# Pretty-print JSON on stdin via bat if available, else pass through untouched.
# (No jq dependency — falls back to raw so it works anywhere.)
_ppjson() {
  if command -v bat >/dev/null; then bat --language=json --style=plain --paging=never
  else cat; fi
}

# curl conveniences (new names — `curl` itself is left alone on purpose).
if command -v curl >/dev/null; then
  # curlj <url> [curl args] — GET and pretty-print the JSON body.
  curlj() { curl -fsS "$@" | _ppjson; }
  # curlh <url> [curl args] — show response headers only (status + headers).
  curlh() { curl -sS -D - -o /dev/null "$@"; }
  # curlt <url> [curl args] — latency breakdown (DNS / connect / TLS / TTFB / total).
  curlt() {
    curl -sS -o /dev/null -w \
'dns:      %{time_namelookup}s\nconnect:  %{time_connect}s\ntls:      %{time_appconnect}s\nttfb:     %{time_starttransfer}s\ntotal:    %{time_total}s\n' \
      "$@"
  }
fi

# grpcurl conveniences — most dev servers are local + non-TLS, so default to
# -plaintext. All pass extra args through (add -H, -import-path, TLS, etc.).
if command -v grpcurl >/dev/null; then
  # gcurl <host:port> <args...> — grpcurl with -plaintext (e.g. gcurl :50051 list).
  gcurl() { grpcurl -plaintext "$@"; }
  # gcurld <host:port> <method> <json> — call a method with a request body.
  gcurld() {
    local host="$1" method="$2" body="${3:-}"
    grpcurl -plaintext -d "$body" "$host" "$method"
  }
  # gcls <host:port> — list services exposed via server reflection.
  gcls() { grpcurl -plaintext "$1" list; }
  # gcdesc <host:port> <symbol> — describe a service/method/message.
  gcdesc() { grpcurl -plaintext "$1" describe "${2:-}"; }
fi

# --- Ollama / local DeepSeek -------------------------------------------------
# Local LLM via Ollama (install + model pull: `./setup.sh --ollama`). The server
# exposes an OpenAI-compatible API on localhost:11434. The real consumer is
# Neovim's codecompanion adapter — which lives in the SEPARATE nvim repo, not
# here — so this block just provides the single source of truth for the model
# name (OLLAMA_DEFAULT_MODEL, read by that adapter) plus a quick terminal helper.
# Guarded by `command -v ollama` so it no-ops on machines without it.
if command -v ollama >/dev/null; then
  # Keep this in sync with OLLAMA_MODEL in setup.sh and the nvim adapter.
  export OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-deepseek-coder-v2:16b}"

  # ai [model] <<<"prompt"  /  ai "prompt..." — one-shot query from the shell.
  # First arg is treated as a model override only if it contains a ':' (the
  # Ollama tag separator); otherwise everything is the prompt.
  ai() {
    local model="$OLLAMA_DEFAULT_MODEL"
    case "${1:-}" in *:*) model="$1"; shift ;; esac
    if [ "$#" -gt 0 ]; then ollama run "$model" "$*"
    else ollama run "$model"; fi
  }
fi

# gh multi-account: keep the active `gh` account aligned with the repo I'm in.
# ONLY matters on a machine with two GitHub accounts (i.e. a work machine).
# On a personal-only machine there's one gh account and the remote never carries
# the `github.com-personal` alias, so _gh_account_for_repo returns nothing and
# ghsync is a no-op — safe to leave in regardless.
#
# Personal repos use the `github.com-personal` SSH alias in their remote; work
# repos use plain `github.com`. ghsync picks the matching gh account.
#
# The `gh` wrapper below runs ghsync before every gh command so I never forget.
# It stays fast by reading both the desired and current account from LOCAL
# sources (git remote + ~/.config/gh/hosts.yml) and only shelling out to the
# slow `gh auth switch` when they actually differ. `command gh` calls the real
# binary, preventing the wrapper from recursing into itself.
if command -v gh >/dev/null; then
  # Map this repo's origin remote -> the gh account that should be active.
  # Adjust the account names here if yours differ (see `gh auth status`).
  _gh_account_for_repo() {
    local url
    url=$(command git config --get remote.origin.url 2>/dev/null) || return 1
    case "$url" in
      *github.com-personal[:/]*) print -r -- "jonathan" ;;          # personal
      *github.com[:/]*)          print -r -- "jonathan-hicks_sfemu" ;; # work
      *) return 1 ;;  # not a github repo (or no remote) — leave gh as-is
    esac
  }

  # Currently-active gh account, read straight from gh's config (no network).
  _gh_active_account() {
    awk '/^github\.com:/{f=1} f&&/^    user:/{print $2; exit}' \
      "${HOME}/.config/gh/hosts.yml" 2>/dev/null
  }

  ghsync() {
    local want
    want=$(_gh_account_for_repo) || return 0          # not a gh repo -> no-op
    [[ "$want" == "$(_gh_active_account)" ]] && return 0  # already correct
    command gh auth switch --hostname github.com --user "$want" >/dev/null 2>&1
  }

  # Wrapper: align the account, then run the real gh with all original args.
  gh() {
    ghsync
    command gh "$@"
  }
fi

# 1Password CLI (op) — multi-account convenience.
# Like the gh setup, the dual-account part only matters on a machine signed into
# both a personal and a work 1Password account (i.e. a work machine). On a
# personal-only machine just the personal account exists; opp still works, opw
# is harmless (errors only if you actually call it), and everything is guarded
# by `command -v op` so the whole block no-ops when op isn't installed.
# `op` stores NO secrets on disk — vault data is encrypted server-side and
# unlocked via the desktop app/biometrics — so this shell glue is safe to track.
if command -v op >/dev/null; then
  # Account shorthands (use the account URLs from `op account list`).
  export OP_PERSONAL_ACCOUNT="my.1password.com"
  export OP_WORK_ACCOUNT="salesforce.1password.com"

  # Default bare `op` to the personal account (override per-call with --account,
  # or use the opw helper below).
  export OP_ACCOUNT="$OP_PERSONAL_ACCOUNT"

  # Per-account helpers: opp = personal, opw = work.
  opp() { op --account "$OP_PERSONAL_ACCOUNT" "$@"; }
  opw() { op --account "$OP_WORK_ACCOUNT" "$@"; }

  # 1Password SSH agent — lets op serve SSH keys. Path differs by OS; only set
  # SSH_AUTH_SOCK if the socket actually exists (agent enabled in the app).
  for _op_sock in \
    "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
    "$HOME/.1password/agent.sock"; do
    [ -S "$_op_sock" ] && export SSH_AUTH_SOCK="$_op_sock" && break
  done
  unset _op_sock

  # Run a command with secrets injected from an op env-file template (op://
  # references resolved at call time, never written to disk or left in the
  # environment afterward). This replaces exporting plaintext secrets globally.
  #   openv <account> <env-file> -- <command...>
  # e.g. openv work ~/.config/op/artifactory.env -- npm install
  openv() {
    local which="$1" envfile="${2/#\~/$HOME}"; shift 2
    local acct; case "$which" in
      work|w)     acct="$OP_WORK_ACCOUNT" ;;
      personal|p) acct="$OP_PERSONAL_ACCOUNT" ;;
      *) print -u2 "openv: first arg must be work|personal"; return 2 ;;
    esac
    op run --account "$acct" --env-file="$envfile" "$@"
  }

  # Convenience: run a command with the Artifactory/Nexus secrets in scope.
  #   artenv -- npm install     (secrets live only for that command)
  artenv() { openv work ~/.config/op/artifactory.env "$@"; }
fi

# Node version management is handled by Volta (automatic per-project switching,
# no shell hook). The previous nvm setup + load-nvmrc chpwd hook was removed —
# it was slow and redundant with Volta.
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
# (SSH_AUTH_SOCK for the 1Password agent is set in the `op` block above.)

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
