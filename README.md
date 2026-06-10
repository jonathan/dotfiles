# dotfiles

Personal cross-platform dotfiles (**macOS** and **Ubuntu/Debian Linux**) for a terminal-centric dev environment: **zsh** (oh-my-zsh + oh-my-posh), **tmux**, **Neovim**, plus a set of modern, fast CLI tools (**eza**, **zoxide**, **fd**, **ripgrep**, **bat**, **fzf**) and **Ghostty** as the terminal, with the Dracula theme throughout.

The shared config files detect the OS at runtime (`uname`/`$OSTYPE`), so the same `.zshrc`/`.tmux.conf` work on both platforms — see [Platform notes](#platform-notes). The Neovim config is maintained as its own git repository and is intentionally **not** in this repo — see [Neovim](#neovim).

## What's in here

| File | Installs to | Purpose |
|------|-------------|---------|
| `.zshrc` | `~/.zshrc` | Main zsh config — oh-my-zsh, plugins, aliases, PATH, fzf/nvm/volta |
| `.zprofile` | `~/.zprofile` | Login-shell setup — Homebrew/Linuxbrew `shellenv`, .NET tools on PATH |
| `.jonathanhicks.omp.json` | `~/.jonathanhicks.omp.json` | oh-my-posh prompt theme (Dracula colors) |
| `.tmux.conf` | `~/.tmux.conf` | tmux config — `C-a` prefix, vi copy mode (OS-aware clipboard), dracula/tmux, vim-tmux navigation |
| `config/bat/config` | `~/.config/bat/config` | bat pager defaults (Dracula theme) |
| `config/git/ignore` | `~/.config/git/ignore` | Global gitignore |
| `config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal config (Dracula) — macOS + Linux |
| `iterm/Dracula.itermcolors` | imported in iTerm2 | iTerm2 Dracula color preset (legacy macOS terminal) |
| `iterm/com.googlecode.iterm2.plist` | iTerm2 prefs | iTerm2 preferences (legacy macOS terminal) |
| `setup.sh` | — | Symlinks the above into `$HOME` (see [Installation](#installation)) |

Files under `config/` mirror their destination under `~/.config/` (e.g. `config/bat/config` → `~/.config/bat/config`).

## Modern CLI tools

`.zshrc` prefers these faster alternatives to the classic tools and falls back gracefully when they aren't installed (e.g. `ls` stays plain `ls` without `eza`):

| Classic | Modern replacement | Used for |
|---------|-------------------|----------|
| `ls` | [`eza`](https://github.com/eza-community/eza) | `ls`/`ll`/`la`/`lt` aliases — icons, git status, tree |
| `cd` | [`zoxide`](https://github.com/ajeetdsouza/zoxide) | frecency-based jumping (`z <dir>`) |
| `find` | [`fd`](https://github.com/sharkdp/fd) | fzf's file/dir source (`FZF_DEFAULT_COMMAND`) |
| `grep` / `ag` | [`ripgrep`](https://github.com/BurntSushi/ripgrep) (`rg`) | fast recursive search |
| `cat` | [`bat`](https://github.com/sharkdp/bat) | syntax-highlighted pager; also `-h`/`--help` output |
| `nvm` | [Volta](https://volta.sh) | per-project Node version switching (no shell hook) |

> **Migrated off nvm:** the old `nvm` + `load-nvmrc` `chpwd` hook was removed from `.zshrc` — it slowed every directory change and duplicated Volta, which handles version switching automatically.

## Prerequisites

The easiest path is `setup.sh` with the right flag for your platform (`--brew` on macOS, `--apt` on Ubuntu/Debian) — see [Installation](#installation). To install manually:

### macOS — [Homebrew](https://brew.sh) (Apple Silicon, `/opt/homebrew`)

```sh
# Shell + prompt + editor + tmux
brew install zsh oh-my-posh neovim tmux git
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/ohmyz.sh/master/tools/install.sh)"  # oh-my-zsh

# Modern CLI tools used by the configs
brew install fzf bat eza zoxide fd ripgrep volta

# Terminal
brew install --cask ghostty
```

### Ubuntu/Debian — apt + a few curl installers

Some packages have name/binary quirks (handled automatically by `.zshrc`, noted here for awareness):

```sh
# In apt — note: fd is `fd-find` (binary fdfind), bat installs binary batcat
sudo apt update
sudo apt install -y zsh git tmux curl fzf bat fd-find ripgrep \
                    wl-clipboard xclip acpi build-essential

# Not in base apt:
#   - eza        -> community apt repo (see setup.sh --apt) or `cargo install eza`
#   - neovim     -> apt's is old; use ppa:neovim-ppa/unstable
#   - oh-my-posh -> curl -s https://ohmyposh.dev/install.sh | bash -s
#   - volta      -> curl https://get.volta.sh | bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/ohmyz.sh/master/tools/install.sh)"  # oh-my-zsh

# Terminal — Ghostty (see https://ghostty.org/docs/install/binary for the apt/deb)
```

`.zshrc` aliases `fd`→`fdfind` and `bat`→`batcat` on Debian/Ubuntu automatically, so commands work the same on both platforms.

The dracula oh-my-zsh theme (`ZSH_THEME="dracula"`) is a custom theme — drop it in `~/.oh-my-zsh/custom/themes/`. The prompt is actually rendered by **oh-my-posh** (see `.zshrc`), so the oh-my-zsh theme is largely cosmetic fallback.

## Installation

This repo expects its files to live at the paths in the table above. The included `setup.sh` symlinks them into `$HOME`, backing up any existing real file to `<file>.bak` first. It's idempotent — re-running only relinks what's missing or wrong.

```sh
git clone <this-repo> "$HOME/projects/dotfiles"
cd "$HOME/projects/dotfiles"
./setup.sh                  # symlink dotfiles only (any OS)
./setup.sh --brew --tpm     # macOS: brew-install the CLI tools + clone tpm
./setup.sh --apt --tpm      # Ubuntu/Debian: apt+curl install the tools + clone tpm
```

Flags (combinable):

- `--brew` — install the tools from [Prerequisites](#prerequisites) via Homebrew (macOS or Linuxbrew), plus oh-my-zsh
- `--apt` — install the tools via apt + curl installers (Ubuntu/Debian), plus oh-my-zsh. Handles the not-in-apt tools (eza, current neovim, oh-my-posh, volta).
- `--tpm` — clone [tpm](https://github.com/tmux-plugins/tpm), the tmux plugin manager

The script detects the OS and resolves the repo from its own location, so it works wherever you clone it.

<details>
<summary>Manual equivalent</summary>

```sh
# Top-level dotfiles (assumes the repo is at $HOME/projects/dotfiles)
ln -sf "$HOME/projects/dotfiles/.zshrc"                  "$HOME/.zshrc"
ln -sf "$HOME/projects/dotfiles/.zprofile"               "$HOME/.zprofile"
ln -sf "$HOME/projects/dotfiles/.jonathanhicks.omp.json" "$HOME/.jonathanhicks.omp.json"
ln -sf "$HOME/projects/dotfiles/.tmux.conf"              "$HOME/.tmux.conf"

# ~/.config files
mkdir -p "$HOME/.config/bat" "$HOME/.config/git" "$HOME/.config/ghostty"
ln -sf "$HOME/projects/dotfiles/config/bat/config"     "$HOME/.config/bat/config"
ln -sf "$HOME/projects/dotfiles/config/git/ignore"     "$HOME/.config/git/ignore"
ln -sf "$HOME/projects/dotfiles/config/ghostty/config" "$HOME/.config/ghostty/config"
```

</details>

Then set up the editor and tmux plugins:

- **Neovim** — clone the separate config repo (see [Neovim](#neovim) below). Plugins are managed there.
- **tmux** — [tpm](https://github.com/tmux-plugins/tpm) (or pass `--tpm` to `setup.sh`):
  ```sh
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```
  Then inside tmux press prefix (`C-a`) + `I` to install plugins.

Finally, the terminal:

- **Ghostty** (both platforms) — reads `~/.config/ghostty/config`, which `setup.sh` links. It selects the built-in **Dracula** theme. Install a [Nerd Font](https://www.nerdfonts.com) and set `font-family` in that file so eza/oh-my-posh glyphs render.
- **iTerm2** (legacy, macOS only) — if you still use it, import `iterm/Dracula.itermcolors` (Settings → Profiles → Colors → Import) and load `iterm/com.googlecode.iterm2.plist` (Settings → General → Preferences → custom folder).

### Secrets / machine-local config

`.zshrc` sources these if present — they are **not** tracked here, by design:

- `~/.env_vars.zsh` — sensitive env vars (API keys, tokens)
- `~/.bootstrap_rc` — machine bootstrap hook

Create them locally as needed.

## Platform notes

The shared config files branch on the OS at runtime rather than keeping separate copies. What differs between macOS and Linux:

| Concern | macOS | Ubuntu/Debian Linux |
|---------|-------|---------------------|
| Homebrew (`.zprofile`) | `/opt/homebrew` | Linuxbrew at `/home/linuxbrew/.linuxbrew`, or skip (apt) — guarded, no-op if absent |
| `ls` fallback (no eza) | BSD `ls -hG` | GNU `ls -h --color=auto` (auto-detected) |
| `fd` / `bat` binaries | `fd` / `bat` | `fdfind` / `batcat` — `.zshrc` aliases them back |
| tmux clipboard | `pbcopy` | `wl-copy` (Wayland) or `xclip` (X11), auto-detected |
| Docker socket | `~/.docker/run/docker.sock` (Docker Desktop) | default `/var/run/docker.sock` — `DOCKER_HOST` left unset |
| `history-substring-search` source | `/opt/homebrew/share/...` | `/usr/share/...` — probed across known paths |
| Terminal | Ghostty (or legacy iTerm2) | Ghostty |

Things to install on Linux that macOS doesn't need: `wl-clipboard` and/or `xclip` (tmux copy), and `acpi` (the tmux status bar's battery readout — already referenced in `status-right`).

## Neovim

Neovim is my primary editor (`EDITOR=nvim`, with `vi` aliased to `nvim` in `.zshrc`). Its config is maintained as its **own git repository** at `~/.config/nvim` (a [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) fork, Lua-based, with its own plugin management). It is intentionally not vendored here to keep a single source of truth. Clone it separately:

```sh
git clone git@github.com-personal:jonathan/kickstart.nvim.git ~/.config/nvim
```

## References

- https://ohmyz.sh
- https://ohmyposh.dev
- https://ghostty.org
- https://draculatheme.com
- https://neovim.io
- https://github.com/nvim-lua/kickstart.nvim
- https://github.com/tmux-plugins/tpm
- https://github.com/junegunn/fzf
- https://github.com/sharkdp/bat
- https://www.nerdfonts.com
- https://www.tmuxcheatsheet.com
