#!/usr/bin/env bash
#
# setup.sh — symlink these dotfiles into $HOME and (optionally) install tools.
#
# Idempotent and safe: an existing real file (not already the correct symlink)
# is backed up to <file>.bak before the symlink is created. Re-running only
# relinks what is missing or wrong.
#
# Cross-platform: works on macOS and Ubuntu/Debian Linux.
#
# Usage:
#   ./setup.sh           # symlink the portable dotfiles only
#   ./setup.sh --brew    # also install CLI tools via Homebrew (macOS or Linuxbrew)
#   ./setup.sh --apt     # also install CLI tools via apt + curl (Ubuntu/Debian)
#   ./setup.sh --tpm     # also clone tpm (tmux plugin manager) if missing
#   ./setup.sh --work    # also link work-only configs (Salesforce Artifactory/Nexus
#                        #   op-run template) — pointless on a personal machine
#   ./setup.sh --ollama  # also install Ollama + pull the local DeepSeek model
#                        #   used by Neovim (codecompanion) — several GB, opt-in
# Flags can be combined, e.g.: ./setup.sh --brew --tpm --work

set -euo pipefail

# Repo root = the directory this script lives in.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS: "macos" or "linux".
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      OS=unknown ;;
esac

# CLI tools the configs use (modern, fast alternatives to the classics).
#   eza     -> ls          fd      -> find
#   zoxide  -> cd          ripgrep -> grep/ag
#   bat     -> cat         fzf     -> fuzzy finder
#   volta   -> node version manager (replaces nvm)
#   dust    -> du          procs   -> ps          btop -> top
#   yq      -> jq, for YAML/TOML (helm values, .strata.yml, *.toml)
#   difftastic -> `difft`, structural/AST diff (complements delta, see .zshrc)
#   hyperfine  -> statistical benchmarking (used to measure zsh startup)
#   lazygit    -> git TUI (inherits the delta pager from ~/.gitconfig)
#   stern / kubectx -> multi-pod log tailing + context/namespace switching
#   bat-extras -> batman/batgrep/batdiff (bat-powered man, grep, diff)
BREW_PACKAGES=(zsh oh-my-posh neovim tmux git \
  fzf bat eza zoxide fd ripgrep volta grpcurl \
  yq hyperfine lazygit dust procs btop difftastic bat-extras \
  stern kubectx)

# The local DeepSeek model pulled by --ollama. Code-focused MoE; ~16GB+ RAM/VRAM.
# Keep this name in sync with OLLAMA_DEFAULT_MODEL in .zshrc (and the codecompanion
# adapter in the separate nvim repo, which reads that env var).
OLLAMA_MODEL="deepseek-coder-v2:16b"

# Parse flags
DO_BREW=0
DO_APT=0
DO_TPM=0
DO_WORK=0
DO_OLLAMA=0
for arg in "$@"; do
  case "$arg" in
    --brew)   DO_BREW=1 ;;
    --apt)    DO_APT=1 ;;
    --tpm)    DO_TPM=1 ;;
    --work)   DO_WORK=1 ;;
    --ollama) DO_OLLAMA=1 ;;
    *) printf 'unknown flag: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

# link <source-relative-to-repo> <destination-absolute>
link() {
  local src="$DOTFILES/$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    printf '  ! skip  %s (missing in repo)\n' "$1"
    return
  fi

  # Already the correct symlink? Nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    printf '  = ok    %s\n' "$dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  # Back up an existing real file or wrong symlink.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    printf '  ~ backup %s -> %s.bak\n' "$dest" "$dest"
  fi

  ln -s "$src" "$dest"
  printf '  + link  %s -> %s\n' "$dest" "$src"
}

# --- helpers for tools that aren't in apt (Linux only) ----------------------
# GitHub release naming isn't uniform, so these two helpers cover the shapes we
# need: resolve the latest tag, and normalize the machine arch per project.

# gh_latest_tag <owner/repo> -> latest release tag, e.g. "v0.44.1" (or "" on
# failure — every caller must handle the empty case).
#
# Deliberately resolves the /releases/latest REDIRECT rather than calling
# api.github.com: the JSON API is rate-limited PER IP for unauthenticated
# requests, and on a corporate network the whole office shares one egress IP, so
# the API reliably returns HTTP 403 "rate limit exceeded" (confirmed on this
# machine). The redirect is served by github.com and isn't subject to that limit.
# Note some projects tag with a leading "v" and some don't — callers that need
# the bare version use ${_tag#v}.
gh_latest_tag() {
  local url
  url="$(curl -sSL -o /dev/null -w '%{url_effective}' \
    "https://github.com/$1/releases/latest" 2>/dev/null)" || return 0
  # Only trust it if we actually landed on a tag page (not the releases index).
  case "$url" in
    */releases/tag/*) printf '%s' "${url##*/}" ;;
    *) return 0 ;;
  esac
}

# arch_as <style> -> this machine's arch in the naming style a project uses.
# Three styles because release-asset naming is not consistent across projects:
#   go    -> amd64  / arm64     (stern)
#   rust  -> x86_64 / aarch64   (difftastic, procs)
#   mixed -> x86_64 / arm64     (lazygit — Go project, Rust-ish arch names)
arch_as() {
  local m; m="$(uname -m)"
  case "$1:$m" in
    go:x86_64|go:amd64)        printf 'amd64' ;;
    go:aarch64|go:arm64)       printf 'arm64' ;;
    rust:x86_64|rust:amd64)    printf 'x86_64' ;;
    rust:aarch64|rust:arm64)   printf 'aarch64' ;;
    mixed:x86_64|mixed:amd64)  printf 'x86_64' ;;
    mixed:aarch64|mixed:arm64) printf 'arm64' ;;
    *) printf '%s' "$m" ;;
  esac
}

# zinit — the zsh plugin manager (.zshrc also self-installs it on first run,
# so this is just to front-load the clone during setup).
install_zinit() {
  local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [ ! -d "$zinit_home" ]; then
    echo "Installing zinit..."
    mkdir -p "$(dirname "$zinit_home")"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_home"
  fi
}

# Optional: install CLI tools via Homebrew (macOS or Linuxbrew)
if [ "$DO_BREW" = "1" ]; then
  if ! command -v brew >/dev/null; then
    echo "brew not found — install Homebrew first: https://brew.sh" >&2
    exit 1
  fi
  echo "Installing CLI tools via Homebrew..."
  brew install "${BREW_PACKAGES[@]}"
  install_zinit
  echo
fi

# Optional: install CLI tools via apt + curl (Ubuntu/Debian)
if [ "$DO_APT" = "1" ]; then
  if ! command -v apt-get >/dev/null; then
    echo "apt-get not found — --apt is for Debian/Ubuntu only" >&2
    exit 1
  fi
  echo "Installing CLI tools via apt..."
  sudo apt-get update
  # Notes on apt package names vs binaries:
  #   fd-find  -> binary is `fdfind`  (.zshrc aliases fd -> fdfind)
  #   bat      -> binary is `batcat`  (.zshrc aliases bat -> batcat)
  #   du-dust  -> binary is `dust`    (the apt package is NOT called `dust`)
  #   eza / oh-my-posh / volta are not in base apt — handled below, as are
  #   yq / procs / difftastic / lazygit / stern / kubectx / bat-extras.
  # btop, yq and hyperfine are in apt from Ubuntu 22.04 / Debian 12 onward;
  # `|| true` keeps an older release from failing the whole run — the GitHub
  # fallbacks below then pick up whatever apt missed.
  sudo apt-get install -y \
    zsh git tmux curl \
    fzf bat fd-find ripgrep \
    wl-clipboard xclip acpi \
    build-essential
  sudo apt-get install -y btop du-dust hyperfine || true

  # yq: apt's `yq` on some releases is the unrelated Python wrapper. Prefer the
  # Go binary (mikefarah/yq) that .zshrc and helm/k8s workflows expect.
  if ! command -v yq >/dev/null; then
    echo "Installing yq (mikefarah/yq) from GitHub releases..."
    if sudo curl -fsSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(arch_as go)"
    then
      sudo chmod +x /usr/local/bin/yq
    else
      # Remove the partial file so it doesn't shadow a later good install.
      echo "  ! yq install failed — skipping"
      sudo rm -f /usr/local/bin/yq
    fi
  fi

  # procs: apt HAS a package named `procs`, but it is an unrelated tool. Always
  # install the Rust ps-replacement from GitHub releases to avoid the collision.
  if ! command -v procs >/dev/null; then
    echo "Installing procs from GitHub releases..."
    # procs ships a .zip (not a tarball), so unzip is a hard prerequisite.
    command -v unzip >/dev/null || sudo apt-get install -y unzip
    _tag="$(gh_latest_tag dalance/procs)"
    _tmp="$(mktemp -d)"
    if [ -z "$_tag" ]; then
      echo "  ! could not resolve latest procs release — skipping"
    elif curl -fsSL -o "$_tmp/procs.zip" \
      "https://github.com/dalance/procs/releases/download/${_tag}/procs-${_tag}-$(arch_as rust)-linux.zip"
    then
      unzip -q -o "$_tmp/procs.zip" -d "$_tmp" \
        && sudo install -m755 "$_tmp/procs" /usr/local/bin/procs
    else
      echo "  ! procs download failed — skipping"
    fi
    rm -rf "$_tmp"
  fi

  # difftastic: not in apt — prebuilt Rust binary from GitHub releases.
  # NOTE: `set -e -o pipefail` is on, so every download below is explicitly
  # tolerated (`|| echo ...`) — a GitHub hiccup or a renamed asset must not
  # abort the whole setup run before the dotfiles get linked.
  if ! command -v difft >/dev/null; then
    echo "Installing difftastic from GitHub releases..."
    _tag="$(gh_latest_tag Wilfred/difftastic)"
    if [ -z "$_tag" ]; then
      echo "  ! could not resolve latest difftastic release — skipping"
    else
      curl -fsSL "https://github.com/Wilfred/difftastic/releases/download/${_tag}/difft-$(arch_as rust)-unknown-linux-gnu.tar.gz" \
        | sudo tar -xz -C /usr/local/bin difft \
        || echo "  ! difftastic install failed — skipping (dft/dfts unavailable)"
    fi
  fi

  # lazygit: not in apt — prebuilt Go binary from GitHub releases. The asset
  # name embeds the version WITHOUT the leading "v" that the tag carries.
  if ! command -v lazygit >/dev/null; then
    echo "Installing lazygit from GitHub releases..."
    _tag="$(gh_latest_tag jesseduffield/lazygit)"
    if [ -z "$_tag" ]; then
      echo "  ! could not resolve latest lazygit release — skipping"
    else
      curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${_tag}/lazygit_${_tag#v}_Linux_$(arch_as mixed).tar.gz" \
        | sudo tar -xz -C /usr/local/bin lazygit \
        || echo "  ! lazygit install failed — skipping"
    fi
  fi

  # stern: not in apt — prebuilt Go binary. Asset name also drops the leading v.
  if ! command -v stern >/dev/null; then
    echo "Installing stern from GitHub releases..."
    _tag="$(gh_latest_tag stern/stern)"
    if [ -z "$_tag" ]; then
      echo "  ! could not resolve latest stern release — skipping"
    else
      curl -fsSL "https://github.com/stern/stern/releases/download/${_tag}/stern_${_tag#v}_linux_$(arch_as go).tar.gz" \
        | sudo tar -xz -C /usr/local/bin stern \
        || echo "  ! stern install failed — skipping (slog/slogn unavailable)"
    fi
  fi

  # kubectx/kubens: shell scripts, no compiled binary — install from the repo.
  if ! command -v kubectx >/dev/null; then
    echo "Installing kubectx/kubens..."
    # Fall back to the default branch if the tag lookup failed — these are plain
    # scripts, so tracking master is acceptable where a pinned tag isn't available.
    _tag="$(gh_latest_tag ahmetb/kubectx)"
    _tag="${_tag:-master}"
    for _t in kubectx kubens; do
      if sudo curl -fsSL -o "/usr/local/bin/$_t" \
        "https://raw.githubusercontent.com/ahmetb/kubectx/${_tag}/$_t"
      then
        sudo chmod +x "/usr/local/bin/$_t"
      else
        echo "  ! $_t install failed — skipping"
        sudo rm -f "/usr/local/bin/$_t"
      fi
    done
  fi

  # bat-extras: not in apt — build from the repo. Its scripts invoke `bat`, but
  # Debian/Ubuntu install the binary as `batcat`, so provide a real `bat` on PATH
  # first (a shim in ~/.local/bin, which .zshrc already puts on PATH). Without
  # this the built batman/batgrep install fine but fail at runtime.
  if ! command -v bat >/dev/null && command -v batcat >/dev/null; then
    echo "Linking batcat -> ~/.local/bin/bat (bat-extras needs a real \`bat\`)..."
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    export PATH="$HOME/.local/bin:$PATH"
  fi
  if ! command -v batman >/dev/null; then
    echo "Installing bat-extras..."
    _tmp="$(mktemp -d)"
    if git clone --depth=1 https://github.com/eth-p/bat-extras.git "$_tmp/bat-extras"; then
      ( cd "$_tmp/bat-extras" \
        && sudo ./build.sh --install --prefix=/usr/local ) || \
        echo "  ! bat-extras install failed — skipping (batman/batgrep unavailable)"
    fi
    rm -rf "$_tmp"
  fi
  unset _tag _tmp _t

  # Neovim: apt's version is old. Prefer the unstable PPA for a current build.
  if ! command -v nvim >/dev/null; then
    echo "Installing a current Neovim (ppa:neovim-ppa/unstable)..."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update && sudo apt-get install -y neovim
  fi

  # eza: not in base apt — use the community apt repo.
  if ! command -v eza >/dev/null; then
    echo "Installing eza from its apt repo..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo apt-get update && sudo apt-get install -y eza
  fi

  # zoxide: apt has it on recent releases; fall back to the official installer.
  if ! command -v zoxide >/dev/null; then
    sudo apt-get install -y zoxide 2>/dev/null || \
      curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi

  # oh-my-posh: not in apt — official installer drops it in ~/.local/bin.
  if ! command -v oh-my-posh >/dev/null; then
    echo "Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
  fi

  # Volta: official installer (same as macOS).
  if [ ! -x "$HOME/.volta/bin/volta" ]; then
    echo "Installing Volta..."
    curl https://get.volta.sh | bash
  fi

  # grpcurl: on recent apt; otherwise grab the prebuilt release tarball.
  if ! command -v grpcurl >/dev/null; then
    sudo apt-get install -y grpcurl 2>/dev/null || {
      echo "Installing grpcurl from GitHub releases..."
      curl -sSL "https://github.com/fullstorydev/grpcurl/releases/latest/download/grpcurl_$(uname -s)_$(uname -m).tar.gz" \
        | sudo tar -xz -C /usr/local/bin grpcurl
    }
  fi

  install_zinit
  echo
fi

# Optional: install Ollama and pull the local DeepSeek model that Neovim
# (codecompanion) talks to. Opt-in because the model is several GB. Ollama
# serves an OpenAI-compatible API on localhost:11434; the nvim adapter and the
# `ai` helper in .zshrc point at that. The model name lives in $OLLAMA_MODEL
# above (mirror it in .zshrc's OLLAMA_DEFAULT_MODEL).
if [ "$DO_OLLAMA" = "1" ]; then
  if ! command -v ollama >/dev/null; then
    echo "Installing Ollama..."
    if [ "$OS" = "macos" ]; then
      # Prefer brew if present (keeps it with the other tools); else the cask app.
      if command -v brew >/dev/null; then
        brew install ollama
        echo "Note: start the server with 'ollama serve' or 'brew services start ollama'."
      else
        echo "brew not found — install the Ollama app from https://ollama.com/download" >&2
      fi
    else
      # Linux: official installer sets up the binary + a systemd service.
      curl -fsSL https://ollama.com/install.sh | sh
    fi
  else
    echo "Ollama already installed."
  fi

  # Pull the model. Needs the server running; nudge it on macos/brew where the
  # daemon isn't automatic. (On Linux the installer's systemd service is up.)
  if command -v ollama >/dev/null; then
    echo "Pulling $OLLAMA_MODEL (this is several GB)..."
    if ! ollama pull "$OLLAMA_MODEL"; then
      echo "  ! pull failed — is the server running? Try 'ollama serve' then:" >&2
      echo "      ollama pull $OLLAMA_MODEL" >&2
    fi
  fi
  echo
fi

echo "Linking dotfiles from $DOTFILES"

# Top-level ~/ dotfiles
link ".zshrc"                  "$HOME/.zshrc"
link ".zprofile"               "$HOME/.zprofile"
link ".jonathanhicks.omp.json" "$HOME/.jonathanhicks.omp.json"
link ".tmux.conf"              "$HOME/.tmux.conf"

# ~/.config files (config/<x> mirrors ~/.config/<x>)
link "config/bat/config"        "$HOME/.config/bat/config"
link "config/git/ignore"        "$HOME/.config/git/ignore"
link "config/ghostty/config"    "$HOME/.config/ghostty/config"

# Claude Code user-level rules (claude/<x> mirrors ~/.claude/<x>). Files in
# ~/.claude/rules/*.md load into every Claude Code session, in every project.
#
# Deliberately NOT ~/.claude/CLAUDE.md: that file is managed by DevBar (it
# rewrites the devbar:optimized-tools block), so tracked content there would be
# clobbered. A user-level rule file is separate and safe. Only .md is discovered.
link "claude/rules/cli-tools.md" "$HOME/.claude/rules/cli-tools.md"

# WORK-MACHINE ONLY: config/op/artifactory.env is an `op run` template of op://
# references for my employer's Artifactory/Nexus registries (used by the `artenv`
# helper in .zshrc). It's useless on a personal machine — nothing to point at —
# so it's only linked when running with --work. The generic `openv` helper in
# .zshrc works without it; write your own env-file for your own secrets.
if [ "$DO_WORK" = "1" ]; then
  link "config/op/artifactory.env" "$HOME/.config/op/artifactory.env"
fi

# Optional: tmux plugin manager
if [ "$DO_TPM" = "1" ]; then
  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "tpm already installed"
  else
    echo "Cloning tpm..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    echo "tpm installed — open tmux and press prefix (C-a) + I to install plugins"
  fi
fi

# Final guidance — tailored to the detected OS.
echo
echo "Done. Remaining manual steps:"
echo "  - Open a new shell (or: source ~/.zshrc) to pick up the zsh config"
echo "  - Make zsh your login shell if it isn't:  chsh -s \"\$(command -v zsh)\""
echo "  - Neovim config is a separate repo:"
echo "      git clone git@github.com-personal:jonathan/kickstart.nvim.git ~/.config/nvim"
if [ "$DO_OLLAMA" = "1" ]; then
  echo "  - DeepSeek/Ollama: ensure the server is running ('ollama serve' on macOS;"
  echo "    systemd service on Linux). The codecompanion adapter lives in the nvim"
  echo "    repo above and reads \$OLLAMA_DEFAULT_MODEL ($OLLAMA_MODEL)."
fi
if [ "$OS" = "macos" ]; then
  echo "  - Terminal: Ghostty reads ~/.config/ghostty/config (Dracula, just linked)."
  echo "    iTerm2 (if still used): import iterm/Dracula.itermcolors + load the plist."
else
  echo "  - Terminal: Ghostty reads ~/.config/ghostty/config (Dracula, just linked)."
  echo "    Install a Nerd Font for icons (https://www.nerdfonts.com) and set it in that file."
fi
