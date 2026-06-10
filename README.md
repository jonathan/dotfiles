# dotfiles

Personal macOS dotfiles for a terminal-centric dev environment: **zsh** (oh-my-zsh + oh-my-posh), **tmux**, **vim**, plus **bat**, **fzf**, and **iTerm2** with the Dracula theme throughout.

Neovim is intentionally **not** in this repo — see [Neovim](#neovim) below.

## What's in here

| File | Installs to | Purpose |
|------|-------------|---------|
| `.zshrc` | `~/.zshrc` | Main zsh config — oh-my-zsh, plugins, aliases, PATH, fzf/nvm/volta |
| `.zprofile` | `~/.zprofile` | Login-shell setup — Homebrew `shellenv`, .NET tools on PATH |
| `.jonathanhicks.omp.json` | `~/.jonathanhicks.omp.json` | oh-my-posh prompt theme (Dracula colors) |
| `.tmux.conf` | `~/.tmux.conf` | tmux config — `C-a` prefix, vi copy mode, dracula/tmux, vim-tmux navigation |
| `.vimrc` | `~/.vimrc` | Vim config — vim-plug, ALE, OmniSharp (C#), vim-go, lightline, Dracula |
| `config/bat/config` | `~/.config/bat/config` | bat pager defaults (Dracula theme) |
| `config/git/ignore` | `~/.config/git/ignore` | Global gitignore |
| `iterm/Dracula.itermcolors` | imported in iTerm2 | iTerm2 Dracula color preset |
| `iterm/com.googlecode.iterm2.plist` | iTerm2 prefs | iTerm2 preferences |

Files under `config/` mirror their destination under `~/.config/` (e.g. `config/bat/config` → `~/.config/bat/config`).

## Prerequisites

Install via [Homebrew](https://brew.sh) (Apple Silicon — installs to `/opt/homebrew`):

```sh
# Shell
brew install zsh oh-my-posh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/ohmyz.sh/master/tools/install.sh)"  # oh-my-zsh

# CLI tools used by the configs
brew install fzf bat git tmux nvm volta

# Editors
brew install vim
```

The dracula oh-my-zsh theme (`ZSH_THEME="dracula"`) is a custom theme — drop it in `~/.oh-my-zsh/custom/themes/`. The prompt is actually rendered by **oh-my-posh** (see `.zshrc`), so the oh-my-zsh theme is largely cosmetic fallback.

## Installation

This repo expects its files to live at the paths in the table above. Symlink them so edits in the repo take effect immediately:

```sh
cd ~/projects/dotfiles

# Top-level dotfiles
ln -sf "$PWD/.zshrc"                 ~/.zshrc
ln -sf "$PWD/.zprofile"              ~/.zprofile
ln -sf "$PWD/.jonathanhicks.omp.json" ~/.jonathanhicks.omp.json
ln -sf "$PWD/.tmux.conf"             ~/.tmux.conf
ln -sf "$PWD/.vimrc"                 ~/.vimrc

# ~/.config files
mkdir -p ~/.config/bat ~/.config/git
ln -sf "$PWD/config/bat/config" ~/.config/bat/config
ln -sf "$PWD/config/git/ignore" ~/.config/git/ignore
```

Then install the per-tool plugin managers:

- **vim** — [vim-plug](https://github.com/junegunn/vim-plug) self-installs on first launch (the bootstrap block at the top of `.vimrc` curls it). Then run `:PlugInstall`.
- **tmux** — [tpm](https://github.com/tmux-plugins/tpm):
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

The Neovim config is maintained as its **own git repository** at `~/.config/nvim` (a [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) fork, Lua-based). It is intentionally not vendored here to keep a single source of truth. Clone it separately:

```sh
git clone git@github.com-personal:jonathan/kickstart.nvim.git ~/.config/nvim
```

The legacy `init.vim` that used to live in this repo has been removed — `.vimrc` remains for plain Vim.

## References

- https://ohmyz.sh
- https://ohmyposh.dev
- https://draculatheme.com
- https://github.com/junegunn/vim-plug
- https://github.com/tmux-plugins/tpm
- https://github.com/junegunn/fzf
- https://github.com/sharkdp/bat
- https://www.tmuxcheatsheet.com
- http://vimsheet.com
