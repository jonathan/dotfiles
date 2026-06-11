# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal **cross-platform** dotfiles (macOS + Ubuntu/Debian Linux) for a terminal-centric dev environment (zsh + tmux + Neovim, Ghostty terminal). There is no build, test, or lint step — editing a config file *is* the change. The repo is the source of truth; the files are expected to live (via symlink) at the corresponding paths in `$HOME` (see the table in `README.md`). Shared files branch on `uname`/`$OSTYPE` at runtime instead of keeping per-OS copies — keep that pattern when editing.

To apply a change you re-source or reload the relevant program rather than "running" anything:
- zsh: `source ~/.zshrc` or open a new shell
- tmux: `tmux source-file ~/.tmux.conf` (or prefix `C-a` then `r`, bound in the conf)
- Neovim: not configured in this repo — see the note below

## File → destination map

`config/<x>` mirrors `~/.config/<x>`. Everything else is a top-level `~/` dotfile.

| Repo file | Lives at | Drives |
|-----------|----------|--------|
| `.zshrc` | `~/.zshrc` | zsh, plugins via **zinit** (deferred); prompt via **oh-my-posh** |
| `.zprofile` | `~/.zprofile` | login shell — Homebrew shellenv + .NET tools |
| `.jonathanhicks.omp.json` | `~/.jonathanhicks.omp.json` | oh-my-posh prompt theme |
| `.tmux.conf` | `~/.tmux.conf` | tmux |
| `config/bat/config` | `~/.config/bat/config` | bat pager defaults |
| `config/git/ignore` | `~/.config/git/ignore` | global gitignore |
| `config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal (Dracula) — both OSes |
| `iterm/` | imported into iTerm2 | Dracula preset + prefs plist (legacy, macOS only) |
| `setup.sh` | — | symlinks the above into `$HOME`; installs tools (`--brew`/`--apt`); `--tpm` clones tpm |

## Installing / applying changes

`./setup.sh` symlinks every tracked dotfile into `$HOME`, backing up existing real files to `<file>.bak`. It's idempotent, detects the OS (`uname`), and resolves the repo from its own location. Flags: `--brew` (macOS/Linuxbrew tool install), `--apt` (Ubuntu/Debian tool install via apt + curl, handling the not-in-apt tools eza/neovim/oh-my-posh/volta), `--tpm` (clone the tmux plugin manager). After symlinking, changes in the repo take effect on the next shell/reload.

## Plugin managers (bootstrap chains)

Each tool uses a different external plugin manager that must be installed before the config works. None are vendored here.

- **zsh → zinit** (`~/.local/share/zinit/zinit.git`). `.zshrc` self-installs zinit if missing, then loads plugins via `zinit wait lucid for ...` (turbo/deferred — they load *after* the first prompt). Plugins: oh-my-zsh's git plugin (`OMZ::plugins/git/...`, for `gst`/`gco`-style aliases), `zsh-users/zsh-autosuggestions`, `zdharma-continuum/fast-syntax-highlighting`, `zsh-users/zsh-history-substring-search`, and docker/kubectl completions. The `OMZ::` snippets pull individual files from the oh-my-zsh repo — that is NOT the oh-my-zsh framework (which was removed for being a ~216ms fixed cost). The visible prompt is **oh-my-posh**, initialized near the bottom of `.zshrc` from `~/.jonathanhicks.omp.json`.
- **tmux → tpm** (`~/.tmux/plugins/tpm`). Plugins are the `@plugin` lines near the bottom; install with prefix (`C-a`) + `I`.
- **Neovim** — managed in its own repo (see below), not here.

## Things that bite

- **Neovim is the primary editor but is NOT in this repo.** The nvim config is a separate git repository at `~/.config/nvim` (a Lua-based kickstart.nvim fork with its own remote, `git@github.com-personal:jonathan/kickstart.nvim.git`). Do not copy its files here. `.zshrc` sets `EDITOR=nvim` and aliases `vi` → `nvim`. There is no Vim config in this repo (the old `.vimrc`/`init.vim` were removed when migrating fully to Neovim).
- **Startup is tuned — don't undo these.** zsh startup is ~0.15s and the design is deliberate; each choice looks changeable but isn't: (1) **plugins use `zinit wait lucid`** (deferred until after first prompt) — that deferral IS the speedup. Dropping `wait` makes startup *slower* than the old oh-my-zsh (measured: 0.31s eager vs 0.15s deferred vs 0.30s oh-my-zsh). (2) **`compinit -C` from a cached `~/.zcompdump`** (the `.zshrc` block picks `-C` unless the dump is >24h old) — skips the slow insecure-dir audit. (3) **load order matters**: fast-syntax-highlighting must load before history-substring-search; the history-substring keybindings live in that plugin's `atload'...'` so they bind after it loads. The oh-my-zsh framework was removed entirely (it was a ~216ms fixed cost). If completions seem stale after adding a tool: `rm -f ~/.zcompdump*; exec zsh`. Profile with `{ echo 'zmodload zsh/zprof'; cat ~/.zshrc; echo 'zprof'; } > /tmp/.zshrc && ZDOTDIR=/tmp zsh -ic exit`. NOTE: `wait` plugins don't load under `zsh -ic` (no real prompt cycle) — to verify features, test interactively or temporarily strip `wait`.
- **Secrets live outside the repo.** `.zshrc` sources `~/.env_vars.zsh` and `~/.bootstrap_rc` if present (untracked, machine-local). Put sensitive or machine-specific env vars there, not in `.zshrc`.
- **Multi-account tooling is work-machine-only, but safe everywhere.** Three related setups assume a machine signed into both a personal and a work account; all degrade to no-ops on a personal-only machine and are guarded so they're harmless to keep tracked:
  - **`gh`** — `.zshrc` defines a `gh` wrapper + `ghsync` that align the active `gh` account to the repo (`github.com-personal` remote → personal, plain `github.com` → work). Account names hardcoded in `_gh_account_for_repo`.
  - **SSH** — `ssh/config.example` documents the `github.com-personal` host-alias + the connection-multiplexing fix (dedicated `ControlPath` so personal/work don't share a socket). `~/.ssh/config` itself is NOT tracked (machine/work-specific, sits next to a private key) — only the sanitized example.
  - **`op` (1Password CLI)** — `.zshrc` (guarded by `command -v op`) sets `opp`/`opw` helpers, `OP_ACCOUNT` default (personal), and an OS-aware `SSH_AUTH_SOCK` for the 1Password SSH agent; completion is deferred via zinit. Account URLs are in `OP_PERSONAL_ACCOUNT`/`OP_WORK_ACCOUNT`. `op` keeps no secrets on disk, so the shell glue is safe to track; `~/.config/op/config` is not tracked. NOTE: `op whoami` always reports "not signed in" under the desktop-app integration even when it's working — test with a real command (`op item list`, `op read`) instead. CLI auth needs the app's Settings → Developer → "Integrate with 1Password CLI" toggle; unlocking the app alone isn't enough.
  - **Secret injection over plaintext env vars** — `openv <work|personal> <env-file> -- <cmd>` runs a command with an env-file of `op://` references resolved by `op run` (secrets exist only for that command, never on disk or in the global env). `artenv` is the Artifactory/Nexus shortcut. The template `config/op/artifactory.env` (→ `~/.config/op/artifactory.env`, symlinked by setup.sh) holds only `op://` refs — safe to track. This replaced exporting ~25 plaintext secrets from `~/.env_vars.zsh` (still untracked; keep non-secrets like usernames/URLs there, move secrets to 1Password). Duplicate env names that share one secret point at the same `op://` ref.
- **Modern CLI tools with fallbacks.** `.zshrc` prefers `eza` (ls), `zoxide` (cd), `fd`/`ripgrep` (fzf source + search), `bat` (cat/help). Each is guarded by `command -v <tool>` so the config still works if a tool is missing — preserve that pattern when adding more. Node versions are managed by **Volta**, not nvm (the old nvm + `load-nvmrc` chpwd hook was removed).
- **Cross-platform branching — keep it OS-aware.** Shared files detect the OS rather than assuming macOS. Key spots: `.zprofile` probes for Homebrew at `/opt/homebrew` or `/home/linuxbrew/.linuxbrew`; `.zshrc` picks the `ls` color flag (`-G` BSD vs `--color=auto` GNU), aliases `fd`→`fdfind` / `bat`→`batcat` on Debian/Ubuntu, sets `DOCKER_HOST` only on macOS, and probes multiple paths for history-substring-search + GnuTLS; `.tmux.conf` selects the clipboard command via `if-shell` (`pbcopy` / `wl-copy` / `xclip`) into `@copy_cmd`. The Intel `/usr/local` compiler-flag lines are commented out. When adding macOS-only or Linux-only behavior, guard it (`[[ "$OSTYPE" == darwin* ]]`, `command -v`, or tmux `if-shell`) rather than hardcoding.
- **Key-binding conventions to preserve:** zsh uses vi keybindings (`bindkey -v`); tmux prefix is remapped to `C-a`. `C-h/j/k/l` do split/pane navigation across tmux and the editor (`vim-tmux-navigator` + the `is_vim` checks in `.tmux.conf`, which also match `nvim`) — changes on one side must match the other.
- **Theme is Dracula everywhere** — oh-my-posh prompt, tmux (`dracula/tmux`), bat, Ghostty (`config/ghostty/config`, built-in theme), iTerm (legacy), and the Neovim config. Keep new additions consistent.
