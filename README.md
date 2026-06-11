# dotfiles

Personal cross-platform dotfiles (**macOS** and **Ubuntu/Debian Linux**) for a terminal-centric dev environment: **zsh** ([zinit](https://github.com/zdharma-continuum/zinit) plugin manager + oh-my-posh prompt), **tmux**, **Neovim**, plus a set of modern, fast CLI tools (**eza**, **zoxide**, **fd**, **ripgrep**, **bat**, **fzf**) and **Ghostty** as the terminal, with the Dracula theme throughout. Shell startup is ~0.15s (zinit loads plugins deferred — see [Shell startup](#shell-startup)).

The shared config files detect the OS at runtime (`uname`/`$OSTYPE`), so the same `.zshrc`/`.tmux.conf` work on both platforms — see [Platform notes](#platform-notes). The Neovim config is maintained as its own git repository and is intentionally **not** in this repo — see [Neovim](#neovim).

## What's in here

| File | Installs to | Purpose |
|------|-------------|---------|
| `.zshrc` | `~/.zshrc` | Main zsh config — zinit plugins (deferred), aliases, PATH, fzf/zoxide/volta |
| `.zprofile` | `~/.zprofile` | Login-shell setup — Homebrew/Linuxbrew `shellenv`, .NET tools on PATH |
| `.jonathanhicks.omp.json` | `~/.jonathanhicks.omp.json` | oh-my-posh prompt theme (Dracula colors) |
| `.tmux.conf` | `~/.tmux.conf` | tmux config — `C-a` prefix, vi copy mode (OS-aware clipboard), dracula/tmux, vim-tmux navigation |
| `config/bat/config` | `~/.config/bat/config` | bat pager defaults (Dracula theme) |
| `config/git/ignore` | `~/.config/git/ignore` | Global gitignore |
| `config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal config (Dracula) — macOS + Linux |
| `config/op/artifactory.env` | `~/.config/op/artifactory.env` | **Work-specific** `op run` template — `op://` refs (no secrets) for `artenv`/Salesforce Artifactory; see [op](#1password-cli-op-multi-account) |
| `iterm/Dracula.itermcolors` | imported in iTerm2 | iTerm2 Dracula color preset (legacy macOS terminal) |
| `iterm/com.googlecode.iterm2.plist` | iTerm2 prefs | iTerm2 preferences (legacy macOS terminal) |
| `ssh/config.example` | — | Template (not symlinked) — two-GitHub-account SSH setup; see [SSH config](#ssh-config) |
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

# Modern CLI tools used by the configs
brew install fzf bat eza zoxide fd ripgrep volta

# Terminal
brew install --cask ghostty
```

zsh plugins (autosuggestions, fast-syntax-highlighting, history-substring-search, the git-aliases plugin) are managed by **zinit**, not Homebrew — `.zshrc` installs zinit and fetches them on first launch. No separate install step.

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

# Terminal — Ghostty (see https://ghostty.org/docs/install/binary for the apt/deb)
```

zsh plugins are managed by **zinit** (self-installed by `.zshrc` on first launch) — no apt/curl step for them. `.zshrc` aliases `fd`→`fdfind` and `bat`→`batcat` on Debian/Ubuntu automatically, so commands work the same on both platforms.

The prompt is rendered by **oh-my-posh** from `~/.jonathanhicks.omp.json` (Dracula colors), so no zsh theme is needed.

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

- `--brew` — install the tools from [Prerequisites](#prerequisites) via Homebrew (macOS or Linuxbrew), plus zinit
- `--apt` — install the tools via apt + curl installers (Ubuntu/Debian), plus zinit. Handles the not-in-apt tools (eza, current neovim, oh-my-posh, volta).
- `--tpm` — clone [tpm](https://github.com/tmux-plugins/tpm), the tmux plugin manager
- `--work` — also link **work-only** configs (the Salesforce Artifactory/Nexus `op run` template). Skip this on a personal machine — it points at work vault items that don't exist there. The portable configs are linked either way.

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

### SSH config

`~/.ssh/config` is **not** symlinked — it's machine/work-specific and lives next to a private key, so it stays out of the repo. But [`ssh/config.example`](ssh/config.example) preserves one portable, easy-to-forget bit: the host-alias setup for using **two GitHub accounts** (work + personal) on one machine, including the connection-multiplexing gotcha where both aliases share a socket and the personal push silently authenticates as the work account. Copy that block into your real `~/.ssh/config` by hand on a new machine; never commit the key it references.

### GitHub CLI (`gh`) multi-account

> **Only relevant on a machine with two GitHub accounts — i.e. a work machine.**
> On a personal-only machine `gh` has a single account, so the wrapper below is a
> harmless no-op (it leaves `gh` untouched when there's nothing to switch). Nothing
> to configure there.

On a work machine, `gh` is logged into both the work and personal accounts (`gh auth login` once per account). `gh`'s active account is a single **global** setting, so commands run against whichever account was last selected — easy to push a gist or open a PR as the wrong identity.

`.zshrc` defines a `ghsync` function and a thin `gh` **wrapper** (guarded by `command -v gh`) that fixes this: before every `gh` command it aligns the active account to the current repo — the `github.com-personal` remote alias → personal account, plain `github.com` → work account. You never have to remember to switch.

- It's fast: the desired account is read from `git remote`, the current one from `~/.config/gh/hosts.yml` (both local, no network), and it only calls the slow `gh auth switch` when they actually differ. `command gh` runs the real binary, so the wrapper can't recurse.
- **Account names are hardcoded** in `_gh_account_for_repo` (in `.zshrc`) — update them if yours differ (`gh auth status` lists them).
- Switching changes the **global** active account, so a `gh` call in a personal repo also flips work terminals (and vice-versa). It's self-correcting — the next `gh` in the other repo flips it back — so in practice it's invisible.

### 1Password CLI (`op`) multi-account

> **The dual-account part is work-machine-only, but the block is safe anywhere.**
> Everything is guarded by `command -v op`, so it no-ops if `op` isn't installed.
> On a personal-only machine you just have the personal account — `opp` works,
> `opw` is simply unused.

`.zshrc` adds 1Password CLI conveniences (guarded by `command -v op`):

- **Account helpers** — `opp` targets the personal account, `opw` the work account (each wraps `op --account <url>`). Account URLs are in `OP_PERSONAL_ACCOUNT` / `OP_WORK_ACCOUNT` — **update them if yours differ** (`op account list`).
- **Default account** — `OP_ACCOUNT` defaults bare `op` commands to the **personal** account; use `opw` (or `--account`) for work.
- **SSH agent** — `SSH_AUTH_SOCK` points at the 1Password SSH agent socket, chosen OS-aware (macOS `~/Library/Group Containers/...` vs Linux `~/.1password/agent.sock`) and only if the socket exists (agent enabled in the app).
- **Completion** — `op completion zsh` is loaded deferred via zinit (forking `op` costs ~60ms, too much for eager startup).
- **Secret injection (`op run`)** — instead of exporting plaintext secrets globally, secrets are pulled from 1Password only for the command that needs them. `openv <work|personal> <env-file> -- <cmd>` is a **generic** wrapper around `op run`: give it any env-file of `op://` references and it resolves them at call time for that one command. This part is reusable for any secret cluster, work or personal.

> **`artenv` + `config/op/artifactory.env` are work-specific — not a general example.**
> They target *my* employer's Salesforce **Artifactory/Nexus** registries (the
> `ARTIFACTORY_*` / `NEXUS_*` vars my work npm/build tooling expects, in my work
> 1Password vault). On a personal machine they have nothing to point at. If you're
> adapting these dotfiles, use the generic `openv` instead and write your own
> env-file template for whatever secrets *you* have — don't expect `artenv` to mean
> anything off my work setup. The tracked [`config/op/artifactory.env`](config/op/artifactory.env)
> holds **only `op://` references, no secrets**, so it's safe to track, but its
> vault/item/field names are mine. Example use on my machine: `artenv -- npm install`.

> **Why this matters:** the old approach kept ~25 secrets as plaintext `export`s in `~/.env_vars.zsh`, loaded into *every* process's environment. Moving the high-value ones into 1Password and injecting them per-command via `op run` removes them from disk and from the global environment. Non-secrets (usernames, emails, URLs) can stay as plain env vars. `~/.env_vars.zsh` itself stays untracked (see [Secrets](#secrets--machine-local-config)).

`op` stores **no secrets on disk** — vault data is encrypted server-side and unlocked via the desktop app/biometrics — so this shell glue is safe to track. The `~/.config/op/config` file (account metadata, device id) is machine-specific and is **not** tracked, same as `~/.ssh/config`.

## Shell startup

zsh startup is ~0.15s. The key decision: **zinit loads plugins deferred** (`wait` — after the first prompt paints), so the shell is interactive almost immediately and plugins finish loading in the background.

- Plugins: the oh-my-zsh **git** plugin (aliases like `gst`/`gco`), `zsh-autosuggestions`, `fast-syntax-highlighting`, `zsh-history-substring-search`, and `docker`/`kubectl` completions — all turbo-loaded.
- Completion init uses a cached `~/.zcompdump` with `compinit -C` (skips the slow security audit). If completions seem stale after installing a new tool: `rm -f ~/.zcompdump*; exec zsh`.
- History: see the migration note below.
- Profile it yourself: `{ echo 'zmodload zsh/zprof'; cat ~/.zshrc; echo 'zprof'; } > /tmp/.zshrc && ZDOTDIR=/tmp zsh -ic exit`

> **Migrated off the oh-my-zsh framework.** It was a ~216ms fixed startup cost (measured with `zmodload zsh/zprof`) regardless of plugins. zinit keeps the same features (git aliases, autosuggestions, syntax highlighting, completions) but loads them deferred, roughly halving startup (~0.30s → ~0.15s). oh-my-posh, fzf, and zoxide are unchanged.

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

- https://github.com/zdharma-continuum/zinit
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
