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
#   ./setup.sh --work    # also link work-only configs (Salesforce Artifactory/Nexus
#                        #   op-run template) — pointless on a personal machine
#   ./setup.sh --ollama  # also install Ollama + pull the local DeepSeek model
#                        #   used by Neovim (codecompanion) — several GB, opt-in
#   ./setup.sh --octomind # also install Octomind (+ octofs) and Ollama, pull a
#                        #   local NVIDIA Nemotron model, and point Octomind at it
#                        #   (telemetry off) — ~20GB download, opt-in
# Flags can be combined, e.g.: ./setup.sh --brew --work

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
#   tpack      -> tmux plugin manager (standalone binary, replaces tpm)
#   tree-sitter-cli -> `tree-sitter` CLI nvim-treesitter's `main` branch shells
#     out to for `:TSUpdate`/`:TSInstall`. Deliberately the brew formula (not
#     cargo) so the binary lands in /opt/homebrew/bin next to `nvim` itself —
#     guaranteed on PATH wherever nvim launches from. The plain `tree-sitter`
#     brew formula only ships the library now; the CLI is a separate formula.
BREW_PACKAGES=(zsh oh-my-posh neovim tmux git \
  fzf bat eza zoxide fd ripgrep volta grpcurl \
  yq hyperfine lazygit dust procs btop difftastic bat-extras \
  stern kubectx tpack tree-sitter-cli)

# The local DeepSeek model pulled by --ollama. Code-focused MoE; ~16GB+ RAM/VRAM.
# Keep this name in sync with OLLAMA_DEFAULT_MODEL in .zshrc (and the codecompanion
# adapter in the separate nvim repo, which reads that env var).
OLLAMA_MODEL="deepseek-coder-v2:16b"

# The local model --octomind pulls and points Octomind at: Mistral's Devstral
# Small, a 24B dense coding-agent model (~14GB at 4-bit) with tool calling but NO
# thinking mode. Non-Chinese-lab, so it's also fine under the work policy. Dense
# was chosen over a 3B-active MoE (Nemotron) because the MoE skimmed/misread files
# on an audit task. Override per run with OCTOMIND_OLLAMA_MODEL=<tag>
# ./setup.sh --octomind. Octomind talks to a derived "<model>-64k" tag (same
# weights, num_ctx baked in) so its 40k-token compression threshold always fits in
# the context window. The ':' in the tag becomes '-' (devstral:24b ->
# devstral-24b-64k) to keep the derived name free of a mid-name tag separator.
OCTOMIND_OLLAMA_MODEL="${OCTOMIND_OLLAMA_MODEL:-devstral:24b}"
OCTOMIND_LOCAL_MODEL="${OCTOMIND_OLLAMA_MODEL//:/-}-64k"
# Octomind's default config sends reasoning_effort = "medium"; Ollama rejects that
# for models without a thinking mode ("does not support thinking"). Devstral
# doesn't think, so default to "none". For a thinking model (e.g. Qwen3,
# Nemotron) run with OCTOMIND_REASONING=medium.
OCTOMIND_REASONING="${OCTOMIND_REASONING:-none}"

# Parse flags
DO_BREW=0
DO_APT=0
DO_WORK=0
DO_OLLAMA=0
DO_OCTOMIND=0
for arg in "$@"; do
  case "$arg" in
    --brew)     DO_BREW=1 ;;
    --apt)      DO_APT=1 ;;
    --work)     DO_WORK=1 ;;
    --ollama)   DO_OLLAMA=1 ;;
    --octomind) DO_OCTOMIND=1 ;;
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
# Four styles because release-asset naming is not consistent across projects:
#   go    -> amd64  / arm64     (stern)
#   rust  -> x86_64 / aarch64   (difftastic, procs)
#   mixed -> x86_64 / arm64     (lazygit — Go project, Rust-ish arch names)
#   node  -> x64    / arm64     (tree-sitter-cli)
arch_as() {
  local m; m="$(uname -m)"
  case "$1:$m" in
    go:x86_64|go:amd64)        printf 'amd64' ;;
    go:aarch64|go:arm64)       printf 'arm64' ;;
    rust:x86_64|rust:amd64)    printf 'x86_64' ;;
    rust:aarch64|rust:arm64)   printf 'aarch64' ;;
    mixed:x86_64|mixed:amd64)  printf 'x86_64' ;;
    mixed:aarch64|mixed:arm64) printf 'arm64' ;;
    node:x86_64|node:amd64)    printf 'x64' ;;
    node:aarch64|node:arm64)   printf 'arm64' ;;
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

  # tree-sitter-cli: not in apt — prebuilt binary from GitHub releases. Needed
  # by Neovim's nvim-treesitter (`main` branch) to build parsers on
  # `:TSUpdate`/`:TSInstall`; without it on PATH that fails with ENOENT.
  # Asset is a single binary gzipped directly (no tarball), named
  # tree-sitter-linux-<arch>.gz.
  if ! command -v tree-sitter >/dev/null; then
    echo "Installing tree-sitter-cli from GitHub releases..."
    _tag="$(gh_latest_tag tree-sitter/tree-sitter)"
    if [ -z "$_tag" ]; then
      echo "  ! could not resolve latest tree-sitter-cli release — skipping"
    else
      curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/${_tag}/tree-sitter-linux-$(arch_as node).gz" \
        | sudo gunzip -c > /tmp/tree-sitter \
        && sudo install -m755 /tmp/tree-sitter /usr/local/bin/tree-sitter \
        && rm -f /tmp/tree-sitter \
        || echo "  ! tree-sitter-cli install failed — skipping (:TSUpdate will fail)"
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

  # tpack: not in apt — prebuilt Go binary from GitHub releases (tmux plugin
  # manager, replaces tpm). Asset name keeps the leading v off the version.
  if ! command -v tpack >/dev/null; then
    echo "Installing tpack from GitHub releases..."
    _tag="$(gh_latest_tag tmuxpack/tpack)"
    if [ -z "$_tag" ]; then
      echo "  ! could not resolve latest tpack release — skipping"
    else
      curl -fsSL "https://github.com/tmuxpack/tpack/releases/download/${_tag}/tpack_${_tag#v}_linux_$(arch_as go).tar.gz" \
        | sudo tar -xz -C /usr/local/bin tpack \
        || echo "  ! tpack install failed — skipping"
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
if [ "$DO_OLLAMA" = "1" ] || [ "$DO_OCTOMIND" = "1" ]; then
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

  # Pull the Neovim (DeepSeek) model — only for --ollama, not --octomind. Needs
  # the server running; nudge it on macos/brew where the daemon isn't automatic.
  # (On Linux the installer's systemd service is up.)
  if [ "$DO_OLLAMA" = "1" ] && command -v ollama >/dev/null; then
    echo "Pulling $OLLAMA_MODEL (this is several GB)..."
    if ! ollama pull "$OLLAMA_MODEL"; then
      echo "  ! pull failed — is the server running? Try 'ollama serve' then:" >&2
      echo "      ollama pull $OLLAMA_MODEL" >&2
    fi
  fi
  echo
fi

# Optional: Octomind (https://octomind.run) — a Rust coding-agent harness —
# wired to a local Ollama model. Opt-in: the default model is ~14GB.
#
# Octomind's file tools run through a separate `octofs` binary (built-in MCP
# server ref); without it every session dies at startup.
#
# Config is patched from Octomind's own generated default (octomind config) so
# it tracks upstream instead of vendoring a 400-line TOML. Each substitution only
# matches an untouched default, so re-running is a no-op and never clobbers edits.
#
# CORPORATE-NETWORK CAVEAT: Octomind is rustls + the macOS system trust store; it
# ignores SSL_CERT_FILE/NODE_EXTRA_CA_CERTS. Behind a TLS-intercepting proxy it
# fails with "invalid peer certificate: UnknownIssuer" for hosted providers
# unless the corporate CA is in the OS trust store. Local Ollama (plain http on
# localhost) is unaffected, which is why this flag targets it.
if [ "$DO_OCTOMIND" = "1" ]; then
  if ! command -v octomind >/dev/null; then
    echo "Installing Octomind..."
    if command -v brew >/dev/null; then
      # Newer Homebrew refuses third-party taps until trusted. Deliberately NOT
      # auto-trusted here — that's a security decision; the hint tells you how.
      brew install muvon/tap/octomind muvon/tap/octofs || {
        echo "  ! brew install failed. If it says 'untrusted tap', review the tap then:" >&2
        echo "      brew trust muvon/tap && brew install muvon/tap/octomind muvon/tap/octofs" >&2
      }
    else
      curl -fsSL https://raw.githubusercontent.com/muvon/octomind/master/install.sh | bash \
        || echo "  ! Octomind install script failed — see https://github.com/muvon/octomind" >&2
    fi
  else
    echo "Octomind already installed."
  fi
  command -v octofs >/dev/null \
    || echo "  ! octofs not found on PATH — Octomind sessions will fail until it's installed" >&2

  # Make sure the Ollama server is up (brew installs it without starting it).
  if command -v ollama >/dev/null; then
    if ! curl -sf -m 2 http://localhost:11434/api/version >/dev/null; then
      if [ "$OS" = "macos" ] && command -v brew >/dev/null; then
        brew services start ollama >/dev/null 2>&1 || true
      fi
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        curl -sf -m 2 http://localhost:11434/api/version >/dev/null && break
        sleep 1
      done
    fi

    echo "Pulling $OCTOMIND_OLLAMA_MODEL (~14GB for the default)..."
    if ollama pull "$OCTOMIND_OLLAMA_MODEL"; then
      _mf="$(mktemp)"
      printf 'FROM %s\nPARAMETER num_ctx 65536\n' "$OCTOMIND_OLLAMA_MODEL" > "$_mf"
      ollama create "$OCTOMIND_LOCAL_MODEL" -f "$_mf" \
        || echo "  ! could not create $OCTOMIND_LOCAL_MODEL" >&2
      rm -f "$_mf"
    else
      echo "  ! pull failed — is the server running? Try 'ollama serve' then re-run." >&2
    fi
  fi

  if command -v octomind >/dev/null; then
    _cfg="${OCTOMIND_DATA_DIR:-$HOME/.local/share/octomind}/config/config.toml"
    [ -f "$_cfg" ] || octomind config >/dev/null 2>&1 || true
    if [ -f "$_cfg" ]; then
      # One-time backup before the first patch (only if a default is still present).
      if grep -qE '^telemetry = true|"octohub:auto"' "$_cfg" && [ ! -e "$_cfg.pre-setup" ]; then
        cp -p "$_cfg" "$_cfg.pre-setup"
      fi
      # sed -i.tmp is the form that works on both BSD (macOS) and GNU sed.
      #  - telemetry off (both keys)
      #  - main / compression / supervisor models -> the local 64k tag
      #  - compression threshold 70k -> 40k so it fits the 64k context
      #  - supervisor off: with it on, sessions didn't exit cleanly against local
      #    Ollama (some requests 500'd) in testing; off exits cleanly
      #  - reasoning_effort medium/high -> $OCTOMIND_REASONING (default none): Ollama
      #    rejects a thinking request for non-thinking models like Devstral
      #  (-E for the medium|high alternation; '#' delimiter since '|' is in it.)
      sed -E -i.tmp \
        -e 's|^telemetry = true|telemetry = false|' \
        -e "s|^name = \"octohub:auto\"|name = \"local:${OCTOMIND_LOCAL_MODEL}\"|" \
        -e "s#^reasoning_effort = \"(medium|high)\"#reasoning_effort = \"${OCTOMIND_REASONING}\"#" \
        -e 's|^threshold = 70000|threshold = 40000|' \
        -e '/^\[supervisor\]$/,/^enabled = /s/^enabled = true/enabled = false/' \
        "$_cfg"
      # The shipped default defines a `context_gatherer` sub-agent whose role
      # doesn't exist, so the model delegating to it errors out. Drop that block.
      if grep -q 'octomind acp context_gatherer' "$_cfg"; then
        sed -i.tmp '/^\[\[agents\]\]$/,/^workdir = "\."$/d' "$_cfg"
      fi
      rm -f "$_cfg.tmp"
      if octomind config --validate >/dev/null 2>&1; then
        echo "Octomind config patched + valid: $_cfg"
      else
        echo "  ! Octomind config failed validation — original saved as $_cfg.pre-setup" >&2
      fi
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

# Final guidance — tailored to the detected OS.
echo
echo "Done. Remaining manual steps:"
echo "  - Open a new shell (or: source ~/.zshrc) to pick up the zsh config"
echo "  - Make zsh your login shell if it isn't:  chsh -s \"\$(command -v zsh)\""
echo "  - Neovim config is a separate repo:"
echo "      git clone git@github.com-personal:jonathan/kickstart.nvim.git ~/.config/nvim"
echo "  - tmux: open tmux and press prefix (C-a) + I to install plugins via tpack"
if [ "$DO_OLLAMA" = "1" ]; then
  echo "  - DeepSeek/Ollama: ensure the server is running ('ollama serve' on macOS;"
  echo "    systemd service on Linux). The codecompanion adapter lives in the nvim"
  echo "    repo above and reads \$OLLAMA_DEFAULT_MODEL ($OLLAMA_MODEL)."
fi
if [ "$DO_OCTOMIND" = "1" ]; then
  echo "  - Octomind: run 'octomind run assistant' (model: local:$OCTOMIND_LOCAL_MODEL)."
  echo "    The Ollama server must be running ('brew services start ollama' on macOS)."
  echo "    Hosted providers fail behind a TLS-intercepting proxy — see the note above"
  echo "    the Octomind block in setup.sh."
fi
if [ "$OS" = "macos" ]; then
  echo "  - Terminal: Ghostty reads ~/.config/ghostty/config (Dracula, just linked)."
  echo "    iTerm2 (if still used): import iterm/Dracula.itermcolors + load the plist."
else
  echo "  - Terminal: Ghostty reads ~/.config/ghostty/config (Dracula, just linked)."
  echo "    Install a Nerd Font for icons (https://www.nerdfonts.com) and set it in that file."
fi
