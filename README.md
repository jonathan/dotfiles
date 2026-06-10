# dotfiles

Personal macOS dotfiles for a terminal-centric dev environment: **zsh** (oh-my-zsh + oh-my-posh), **tmux**, **Neovim**, plus a set of modern, fast CLI tools (**eza**, **zoxide**, **fd**, **ripgrep**, **bat**, **fzf**) and **iTerm2**, with the Dracula theme throughout.

The Neovim config is maintained as its own git repository and is intentionally **not** in this repo — see [Neovim](#neovim) below.

## What's in here

| File | Installs to | Purpose |
|------|-------------|---------|
| `.zshrc` | `~/.zshrc` | Main zsh config — oh-my-zsh, plugins, aliases, PATH, fzf/nvm/volta |
| `.zprofile` | `~/.zprofile` | Login-shell setup — Homebrew `shellenv`, .NET tools on PATH |
| `.jonathanhicks.omp.json` | `~/.jonathanhicks.omp.json` | oh-my-posh prompt theme (Dracula colors) |
| `.tmux.conf` | `~/.tmux.conf` | tmux config — `C-a` prefix, vi copy mode, dracula/tmux, vim-tmux navigation |
| `config/bat/config` | `~/.config/bat/config` | bat pager defaults (Dracula theme) |
| `config/git/ignore` | `~/.config/git/ignore` | Global gitignore |
| `iterm/Dracula.itermcolors` | imported in iTerm2 | iTerm2 Dracula color preset |
| `iterm/com.googlecode.iterm2.plist` | iTerm2 prefs | iTerm2 preferences |
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

Install via [Homebrew](https://brew.sh) (Apple Silicon — installs to `/opt/homebrew`). The easiest path is `./setup.sh --brew` (see [Installation](#installation)), which installs everything below; or do it manually:

```sh
# Shell + prompt + editor + tmux
brew install zsh oh-my-posh neovim tmux git
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/ohmyz.sh/master/tools/install.sh)"  # oh-my-zsh

# Modern CLI tools used by the configs
brew install fzf bat eza zoxide fd ripgrep volta
```

The dracula oh-my-zsh theme (`ZSH_THEME="dracula"`) is a custom theme — drop it in `~/.oh-my-zsh/custom/themes/`. The prompt is actually rendered by **oh-my-posh** (see `.zshrc`), so the oh-my-zsh theme is largely cosmetic fallback.

## Installation

This repo expects its files to live at the paths in the table above. The included `setup.sh` symlinks them into `$HOME`, backing up any existing real file to `<file>.bak` first. It's idempotent — re-running only relinks what's missing or wrong.

```sh
git clone <this-repo> "$HOME/projects/dotfiles"
cd "$HOME/projects/dotfiles"
./setup.sh                  # symlink dotfiles only
./setup.sh --brew --tpm     # also brew-install the CLI tools + clone tpm
```

Flags (combinable):

- `--brew` — `brew install` the tools from [Prerequisites](#prerequisites) (and oh-my-zsh if missing)
- `--tpm` — clone [tpm](https://github.com/tmux-plugins/tpm), the tmux plugin manager

The script resolves the repo from its own location, so it works wherever you clone it.

<details>
<summary>Manual equivalent</summary>

```sh
# Top-level dotfiles (assumes the repo is at $HOME/projects/dotfiles)
ln -sf "$HOME/projects/dotfiles/.zshrc"                  "$HOME/.zshrc"
ln -sf "$HOME/projects/dotfiles/.zprofile"               "$HOME/.zprofile"
ln -sf "$HOME/projects/dotfiles/.jonathanhicks.omp.json" "$HOME/.jonathanhicks.omp.json"
ln -sf "$HOME/projects/dotfiles/.tmux.conf"              "$HOME/.tmux.conf"

# ~/.config files
mkdir -p "$HOME/.config/bat" "$HOME/.config/git"
ln -sf "$HOME/projects/dotfiles/config/bat/config" "$HOME/.config/bat/config"
ln -sf "$HOME/projects/dotfiles/config/git/ignore" "$HOME/.config/git/ignore"
```

</details>

Then set up the editor and tmux plugins:

- **Neovim** — clone the separate config repo (see [Neovim](#neovim) below). Plugins are managed there.
- **tmux** — [tpm](https://github.com/tmux-plugins/tpm) (or pass `--tpm` to `setup.sh`):
  ```sh
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```
  Then inside tmux press prefix (`C-a`) + `I` to install plugins.

Finally:

- **iTerm2** — import `iterm/Dracula.itermcolors` (Settings → Profiles → Colors → Import), and point iTerm2 at `iterm/com.googlecode.iterm2.plist` (Settings → General → Preferences → load from a custom folder).

### Secrets / machine-local config

`.zshrc` sources these if present — they are **not** tracked here, by design:

- `~/.env_vars.zsh` — sensitive env vars (API keys, tokens)
- `~/.bootstrap_rc` — machine bootstrap hook

Create them locally as needed.

## Neovim

Neovim is my primary editor (`EDITOR=nvim`, with `vi` aliased to `nvim` in `.zshrc`). Its config is maintained as its **own git repository** at `~/.config/nvim` (a [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) fork, Lua-based, with its own plugin management). It is intentionally not vendored here to keep a single source of truth. Clone it separately:

```sh
git clone git@github.com-personal:jonathan/kickstart.nvim.git ~/.config/nvim
```

## References

- https://ohmyz.sh
- https://ohmyposh.dev
- https://draculatheme.com
- https://neovim.io
- https://github.com/nvim-lua/kickstart.nvim
- https://github.com/tmux-plugins/tpm
- https://github.com/junegunn/fzf
- https://github.com/sharkdp/bat
- https://www.tmuxcheatsheet.com
