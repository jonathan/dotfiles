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
#   ./setup.sh           # symlink dotfiles only
#   ./setup.sh --brew    # also install CLI tools via Homebrew (macOS or Linuxbrew)
#   ./setup.sh --apt     # also install CLI tools via apt + curl (Ubuntu/Debian)
#   ./setup.sh --tpm     # also clone tpm (tmux plugin manager) if missing
# Flags can be combined, e.g.: ./setup.sh --apt --tpm

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
BREW_PACKAGES=(zsh oh-my-posh neovim tmux git \
  fzf bat eza zoxide fd ripgrep volta)

# Parse flags
DO_BREW=0
DO_APT=0
DO_TPM=0
for arg in "$@"; do
  case "$arg" in
    --brew) DO_BREW=1 ;;
    --apt)  DO_APT=1 ;;
    --tpm)  DO_TPM=1 ;;
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

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/ohmyz.sh/master/tools/install.sh)"
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
  install_oh_my_zsh
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
  #   eza / oh-my-posh / volta are not in base apt — handled below.
  sudo apt-get install -y \
    zsh git tmux curl \
    fzf bat fd-find ripgrep \
    wl-clipboard xclip acpi \
    build-essential

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

  install_oh_my_zsh
  echo
fi

echo "Linking dotfiles from $DOTFILES"

# Top-level ~/ dotfiles
link ".zshrc"                  "$HOME/.zshrc"
link ".zprofile"               "$HOME/.zprofile"
link ".jonathanhicks.omp.json" "$HOME/.jonathanhicks.omp.json"
link ".tmux.conf"              "$HOME/.tmux.conf"

# ~/.config files (config/<x> mirrors ~/.config/<x>)
link "config/bat/config"     "$HOME/.config/bat/config"
link "config/git/ignore"     "$HOME/.config/git/ignore"
link "config/ghostty/config" "$HOME/.config/ghostty/config"

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
if [ "$OS" = "macos" ]; then
  echo "  - Terminal: Ghostty reads ~/.config/ghostty/config (Dracula, just linked)."
  echo "    iTerm2 (if still used): import iterm/Dracula.itermcolors + load the plist."
else
  echo "  - Terminal: Ghostty reads ~/.config/ghostty/config (Dracula, just linked)."
  echo "    Install a Nerd Font for icons (https://www.nerdfonts.com) and set it in that file."
fi
