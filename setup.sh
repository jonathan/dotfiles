#!/usr/bin/env bash
#
# setup.sh — symlink these dotfiles into $HOME.
#
# Idempotent and safe: an existing real file (not already the correct symlink)
# is backed up to <file>.bak before the symlink is created. Re-running only
# relinks what is missing or wrong.
#
# Usage:
#   ./setup.sh           # symlink dotfiles
#   ./setup.sh --brew    # also `brew install` the CLI tools the configs use
#   ./setup.sh --tpm     # also clone tpm (tmux plugin manager) if missing
# Flags can be combined: ./setup.sh --brew --tpm

set -euo pipefail

# Repo root = the directory this script lives in.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# CLI tools the configs use (modern, fast alternatives to the classics).
#   eza     -> ls          fd      -> find
#   zoxide  -> cd          ripgrep -> grep/ag
#   bat     -> cat         fzf     -> fuzzy finder
#   volta   -> node version manager (replaces nvm)
BREW_PACKAGES=(zsh oh-my-posh neovim tmux git \
  fzf bat eza zoxide fd ripgrep volta)

# Parse flags
DO_BREW=0
DO_TPM=0
for arg in "$@"; do
  case "$arg" in
    --brew) DO_BREW=1 ;;
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

# Optional: install CLI tools via Homebrew
if [ "$DO_BREW" = "1" ]; then
  if ! command -v brew >/dev/null; then
    echo "brew not found — install Homebrew first: https://brew.sh" >&2
    exit 1
  fi
  echo "Installing CLI tools via Homebrew..."
  brew install "${BREW_PACKAGES[@]}"
  # oh-my-zsh isn't a brew formula — install it if missing
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/ohmyz.sh/master/tools/install.sh)"
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
link "config/bat/config" "$HOME/.config/bat/config"
link "config/git/ignore" "$HOME/.config/git/ignore"

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

cat <<'EOF'

Done. Remaining manual steps:
  - Open a new shell (or: source ~/.zshrc) to pick up the zsh config
  - Neovim config is a separate repo:
      git clone git@github.com-personal:jonathan/kickstart.nvim.git ~/.config/nvim
  - iTerm2: import iterm/Dracula.itermcolors and load iterm/com.googlecode.iterm2.plist
EOF
