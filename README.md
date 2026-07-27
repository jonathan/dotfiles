# dotfiles

Personal cross-platform dotfiles (**macOS** and **Ubuntu/Debian Linux**) for a terminal-centric dev environment: **zsh** ([zinit](https://github.com/zdharma-continuum/zinit) plugin manager + oh-my-posh prompt), **tmux**, **Neovim**, plus a set of modern, fast CLI tools (**eza**, **zoxide**, **fd**, **ripgrep**, **bat**, **fzf**) and **Ghostty** as the terminal, with the Dracula theme throughout. Shell startup is ~0.15s (zinit loads plugins deferred — see [Shell startup](#shell-startup)).

The shared config files detect the OS at runtime (`uname`/`$OSTYPE`), so the same `.zshrc`/`.tmux.conf` work on both platforms — see [Platform notes](#platform-notes). There's also a **native Windows / PowerShell** variant under `windows/` for a work VM — see [Windows](#windows). The Neovim config is maintained as its own git repository and is intentionally **not** in this repo — see [Neovim](#neovim).

## What's in here

| File | Installs to | Purpose |
|------|-------------|---------|
| `.zshrc` | `~/.zshrc` | Main zsh config — zinit plugins (deferred), aliases, PATH, fzf/zoxide/volta |
| `.zprofile` | `~/.zprofile` | Login-shell setup — Homebrew/Linuxbrew `shellenv`, .NET tools on PATH |
| `.jonathanhicks.omp.json` | `~/.jonathanhicks.omp.json` | oh-my-posh prompt theme (Dracula colors) |
| `.tmux.conf` | `~/.tmux.conf` | tmux config — `C-a` prefix, vi copy mode (OS-aware clipboard), dracula/tmux, vim-tmux navigation (bindings: [TMUX.md](TMUX.md)) |
| `config/bat/config` | `~/.config/bat/config` | bat pager defaults (Dracula theme) |
| `config/git/ignore` | `~/.config/git/ignore` | Global gitignore |
| `config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal config (Dracula) — macOS + Linux |
| `config/op/artifactory.env` | `~/.config/op/artifactory.env` | **Work-specific** `op run` template — `op://` refs (no secrets) for `artenv`/Salesforce Artifactory; see [op](#1password-cli-op-multi-account) |
| `iterm/Dracula.itermcolors` | imported in iTerm2 | iTerm2 Dracula color preset (legacy macOS terminal) |
| `iterm/com.googlecode.iterm2.plist` | iTerm2 prefs | iTerm2 preferences (legacy macOS terminal) |
| `ssh/config.example` | — | Template (not symlinked) — two-GitHub-account SSH setup; see [SSH config](#ssh-config) |
| `setup.sh` | — | Symlinks the above into `$HOME` (macOS/Linux; see [Installation](#installation)) |
| `windows/Microsoft.PowerShell_profile.ps1` | `$PROFILE.CurrentUserAllHosts` | **Windows** — PowerShell profile (prompt, PSReadLine, CLI aliases, op/curl/grpcurl); see [Windows](#windows) |
| `windows/setup.ps1` | — | **Windows** — links the profile + shared configs, installs tools via winget |

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
| `man` | [`bat-extras`](https://github.com/eth-p/bat-extras) (`batman`) | man pages through bat; also ships `batgrep`/`batdiff` |
| `top` | [`btop`](https://github.com/aristocratos/btop) | resource monitor (aliased over `top`) |
| `du` | [`dust`](https://github.com/bootandy/dust) | sorted disk-usage tree with bars (**not** aliased — see below) |
| `ps` | [`procs`](https://github.com/dalance/procs) | human-readable process list (**not** aliased — see below) |
| `jq` (for YAML) | [`yq`](https://github.com/mikefarah/yq) | same query language over YAML/TOML/XML (helm values, `.strata.yml`) |
| `nvm` | [Volta](https://volta.sh) | per-project Node version switching (no shell hook) |

Plus tools with no classic equivalent:

| Tool | Used for |
|------|----------|
| [`lazygit`](https://github.com/jesseduffield/lazygit) | git TUI (`lg`) — interactive staging/hunk-splitting; inherits the delta pager |
| [`difftastic`](https://github.com/Wilfred/difftastic) | structural (AST) diff — `dft` / `dfts` |
| [`hyperfine`](https://github.com/sharkdp/hyperfine) | statistical benchmarking (used for the startup numbers below) |
| [`stern`](https://github.com/stern/stern) | tail logs across all pods matching a regex — `slog` / `slogn` |
| [`kubectx`](https://github.com/ahmetb/kubectx) | switch kube context (`kctx`) / namespace (`kns`) |

> **`dust` and `procs` are installed but deliberately not aliased over `du`/`ps`.** Their flags are incompatible with the invocations that are muscle memory (`du -sh *`, `ps aux`, `ps -ef`), so aliasing them would just produce errors. Same reasoning as leaving `curl`/`grpcurl` unaliased — new names alongside, not on top of. `btop` *is* aliased over `top`, since `top`'s flags aren't worth preserving (`command top` still reaches the real binary).

> **`difftastic` does not replace `delta`.** `delta` stays the git pager (configured in `~/.gitconfig`, which is machine-local and not tracked here) for `log`/`show`/`diff`. `difft` diffs the *syntax tree*, so a reindent or a moved brace reports "No syntactic changes" where a line diff shows edits. It's wired as opt-in `dft`/`dfts` functions rather than git config, precisely so it doesn't take over the default path.

> **Migrated off nvm:** the old `nvm` + `load-nvmrc` `chpwd` hook was removed from `.zshrc` — it slowed every directory change and duplicated Volta, which handles version switching automatically.

### HTTP / gRPC helpers

`.zshrc` adds small functions for `curl` and [`grpcurl`](https://github.com/fullstorydev/grpcurl) (each guarded by `command -v`, all pass extra args through). `curl` and `grpcurl` themselves are left unaliased — these are new names alongside them.

| Helper | Does | Expands to |
|--------|------|------------|
| `curlj <url>` | GET + pretty-print JSON (via `bat`, raw fallback) | `curl -fsS … \| bat -l json` |
| `curlh <url>` | response headers only | `curl -sS -D - -o /dev/null …` |
| `curlt <url>` | latency breakdown (DNS/connect/TLS/TTFB/total) | `curl -w <timing template>` |
| `gcurl <host> …` | grpcurl on a local non-TLS server | `grpcurl -plaintext …` |
| `gcurld <host> <method> <json>` | call a method with a request body | `grpcurl -plaintext -d <json> …` |
| `gcls <host>` | list services (server reflection) | `grpcurl -plaintext <host> list` |
| `gcdesc <host> <symbol>` | describe a service/method/message | `grpcurl -plaintext <host> describe <symbol>` |

The `grpcurl` helpers default to `-plaintext` since local/dev gRPC servers are usually non-TLS; for TLS just use `grpcurl` directly or pass your own flags. Pretty-printing needs no `jq` — it uses `bat` if present, else prints raw.

## Prerequisites

The easiest path is `setup.sh` with the right flag for your platform (`--brew` on macOS, `--apt` on Ubuntu/Debian) — see [Installation](#installation). To install manually:

### macOS — [Homebrew](https://brew.sh) (Apple Silicon, `/opt/homebrew`)

```sh
# Shell + prompt + editor + tmux
brew install zsh oh-my-posh neovim tmux git

# Modern CLI tools used by the configs
brew install fzf bat eza zoxide fd ripgrep volta grpcurl
brew install yq hyperfine lazygit dust procs btop difftastic bat-extras \
             stern kubectx

# Terminal
brew install --cask ghostty
```

zsh plugins (autosuggestions, fast-syntax-highlighting, history-substring-search, the git-aliases plugin) are managed by **zinit**, not Homebrew — `.zshrc` installs zinit and fetches them on first launch. No separate install step.

### Ubuntu/Debian — apt + a few curl installers

Some packages have name/binary quirks (handled automatically by `.zshrc`, noted here for awareness):

```sh
# In apt — note: fd is `fd-find` (binary fdfind), bat installs binary batcat,
# and dust is packaged as `du-dust`
sudo apt update
sudo apt install -y zsh git tmux curl fzf bat fd-find ripgrep \
                    wl-clipboard xclip acpi build-essential
sudo apt install -y btop du-dust hyperfine   # only on 22.04+ / Debian 12+

# Not in base apt:
#   - eza        -> community apt repo (see setup.sh --apt) or `cargo install eza`
#   - neovim     -> apt's is old; use ppa:neovim-ppa/unstable
#   - oh-my-posh -> curl -s https://ohmyposh.dev/install.sh | bash -s
#   - volta      -> curl https://get.volta.sh | bash
#   - yq         -> apt's `yq` may be the unrelated Python wrapper; use
#                   mikefarah/yq's release binary instead
#   - procs      -> apt HAS a `procs` package, but it is a DIFFERENT tool;
#                   install dalance/procs from GitHub releases
#   - difftastic / lazygit / stern -> GitHub release binaries
#   - kubectx    -> shell scripts from the repo
#   - bat-extras -> build.sh from the repo; needs a real `bat` on PATH, so
#                   setup.sh symlinks batcat -> ~/.local/bin/bat first

# `./setup.sh --apt` does all of the above, including the fallbacks.

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
- `--apt` — install the tools via apt + curl installers (Ubuntu/Debian), plus zinit. Handles the not-in-apt tools (eza, current neovim, oh-my-posh, volta, grpcurl, yq, procs, difftastic, lazygit, stern, kubectx, bat-extras).
- `--tpm` — clone [tpm](https://github.com/tmux-plugins/tpm), the tmux plugin manager
- `--work` — also link **work-only** configs (the Salesforce Artifactory/Nexus `op run` template). Skip this on a personal machine — it points at work vault items that don't exist there. The portable configs are linked either way.
- `--ollama` — install [Ollama](https://ollama.com) and pull the local **DeepSeek** model Neovim talks to (`deepseek-coder-v2:16b`). Opt-in and separate from `--brew`/`--apt` because the model is several GB. See [Local LLM (Ollama + DeepSeek)](#local-llm-ollama--deepseek).

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
  Then inside tmux press prefix (`C-a`) + `I` to install plugins. For day-to-day
  bindings (sessions, splits, vim-pane navigation, copy mode), see the
  [tmux cheatsheet](TMUX.md).

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

#### Setting up: moving env-var secrets into 1Password

A walkthrough for replacing plaintext `export FOO_TOKEN=…` lines with on-demand 1Password lookups. Generic — substitute your own vault/item/field names.

**1. Install the CLI and enable the desktop-app integration.**

```sh
brew install 1password-cli            # macOS; or see https://1password.com/downloads/command-line/
op --version
```

Then in the **1Password desktop app**: Settings → Developer → check **"Integrate with 1Password CLI"** (and enable Touch ID / biometric unlock). Quit and relaunch the app if the CLI doesn't connect.

> **Don't health-check with `op whoami`** — under the desktop-app integration it reports "not signed in" even when working. Test with a real command instead: `op item list` or `op read …`.

**2. Store the secret in a vault.** Either in the desktop app (add fields to an item), or via the CLI. Create a new item:

```sh
# --category and --title are required; [password] makes a field concealed.
op item create --category "API Credential" --title "My Service" --vault Private \
  'token[password]=PUT_REAL_TOKEN_HERE' \
  'username=me@example.com'
```

Or add fields to an existing item (no `--category` needed):

```sh
op item edit "My Service" --vault Private \
  'api_key[password]=PUT_REAL_KEY_HERE' \
  'base_url[text]=https://api.example.com'
```

> Typing a literal secret puts it in shell history. Prefer adding fields in the **desktop app**, or reference an existing env var so the literal never appears: `op item edit "My Service" "token[password]=$EXISTING_TOKEN"` (prefix the line with a space if you have `HIST_IGNORE_SPACE`).

**3. Find the `op://` reference path.** It's `op://<vault>/<item>/<field>`. List field labels (no values shown) with:

```sh
op item get "My Service" --vault Private --format=json | grep -E '"(label|id)"'
# then read one to confirm the path resolves:
op read "op://Private/My Service/token"
```

**4. Write a reference-only env-file** (safe — no secrets, just pointers). Name fields multiple times if your tooling expects several env names for one secret:

```sh
# ~/.config/op/myservice.env
export MY_SERVICE_TOKEN="op://Private/My Service/token"
export MY_SERVICE_USER="op://Private/My Service/username"
export MY_SERVICE_URL="op://Private/My Service/base_url"
```

**5. Run commands with the secrets injected** for that command only — never exported globally, never written to disk:

```sh
openv personal ~/.config/op/myservice.env -- mycli deploy
# or directly:
op run --account my.1password.com --env-file=~/.config/op/myservice.env -- mycli deploy
```

Verify everything resolves without printing the values:

```sh
openv personal ~/.config/op/myservice.env -- sh -c 'echo "${MY_SERVICE_TOKEN:+set}"'   # -> "set"
```

**6. Remove the plaintext.** Once `openv` works, delete the corresponding `export` lines from `~/.env_vars.zsh`. Keep non-secrets (usernames, URLs) as plain env vars if you prefer — there's no benefit to vaulting those. Open a fresh shell and confirm the secret is gone from the normal environment (`echo "${MY_SERVICE_TOKEN:-gone}"`) but present under `openv`.

> **Optional convenience:** wrap a frequently-used env-file in a one-word function, like the `artenv` helper does:
> `myenv() { openv personal ~/.config/op/myservice.env "$@"; }` → then `myenv -- mycli deploy`.

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

### Touch ID for `sudo` (macOS)

A manual, **per-machine** step — not symlink-managed by `setup.sh`, because it edits a system path (`/etc/pam.d/`), not a `$HOME` dotfile. It makes `sudo` (and the password prompts during `brew` cask installs/updates) accept Touch ID instead of a typed password. Note: 1Password/`op` can't do this — `sudo` auth goes through PAM (`pam_tid.so`), not the 1Password agent (which only handles SSH keys / secret injection).

On Sonoma (14) and later, the supported way is a drop-in `sudo_local` file that **survives macOS updates** (don't edit `/etc/pam.d/sudo` directly — `auth include sudo_local` is already there). The extra `pam_reattach` line makes Touch ID work **inside tmux/screen** (without it, `sudo` in a tmux pane silently falls back to a password):

```sh
brew install pam-reattach     # so Touch ID prompts work inside tmux
sudo tee /etc/pam.d/sudo_local >/dev/null <<'EOF'
# sudo_local: survives system updates; included by /etc/pam.d/sudo
# pam_reattach (Touch ID inside tmux) must come before pam_tid
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
auth       sufficient     pam_tid.so
EOF
```

Test in a **new** shell: `sudo -k; sudo whoami` should prompt for a fingerprint. Caveats: Touch ID only works at the physical machine — over SSH it correctly falls back to a password; and the `pam_reattach.so` path is `/opt/homebrew/...` on Apple Silicon (Intel Homebrew uses `/usr/local/...`).

## Windows

A native **PowerShell** variant lives under `windows/`, for a **work VM** where WSL isn't available. It's not the zsh setup — Windows has no native zsh or tmux — but it recreates the parts that port cleanly: the same **oh-my-posh Dracula prompt** (the `.jonathanhicks.omp.json` theme is shared, unchanged), the same modern CLI tools, and **PSReadLine** as the native stand-in for autosuggestions + syntax highlighting + history search (with Vi edit mode, matching `bindkey -v`).

Because the VM is single-account, the Windows profile **omits** the personal/work multi-account machinery (no `gh` switcher, no `opp`/`opw` split — just one account).

```powershell
git clone <this-repo> $HOME\projects\dotfiles
cd $HOME\projects\dotfiles
pwsh -File windows\setup.ps1                # link the profile + shared configs
pwsh -File windows\setup.ps1 -Winget        # also install tools via winget
pwsh -File windows\setup.ps1 -Winget -Work  # also link the work op-run template
```

| zsh feature | Windows equivalent |
|-------------|--------------------|
| oh-my-posh prompt | same, `oh-my-posh init pwsh` with the shared theme |
| zinit plugins (autosuggest / highlight / history) | **PSReadLine** (built into PS7), Vi edit mode |
| `eza`/`zoxide`/`fd`/`rg`/`bat`/`fzf` | same tools via winget; aliases/functions in the profile |
| `curlj`/`gcurl`/… helpers | ported as PowerShell functions (`curl.exe`, `grpcurl`) |
| `op run` / `artenv` | `openv <env-file> -- <cmd>` / `artenv` (work account only) |
| `gh`/`op` multi-account, tmux, Ghostty | **dropped** — single account; no tmux/Ghostty on native Windows |
| secrets/per-VM extras | `~\.env_vars.ps1`, `~\.bootstrap.ps1` (untracked) |

> **Caveats.** Symlinks on Windows need Developer Mode (or an elevated shell); `setup.ps1` falls back to copying and warns if it can't link. Neovim's config goes in `~\AppData\Local\nvim` (clone the separate repo there). Install a Nerd Font and set it in Windows Terminal for prompt/eza glyphs. **This variant is authored on macOS and hasn't been run on Windows** — review before relying on it.

## Local LLM (Ollama + DeepSeek)

A local, offline code assistant for Neovim, run via [Ollama](https://ollama.com). `./setup.sh --ollama` installs Ollama and pulls **`deepseek-coder-v2:16b`** (a code-focused MoE model; budget ~16GB+ RAM/VRAM). It's a separate opt-in flag — not bundled into `--brew`/`--apt` — because the model download is several GB.

What lives **where** (this matters — the editor config is deliberately not in this repo):

- **`setup.sh`** (`--ollama`) — installs Ollama (brew on macOS, the official installer + systemd service on Linux) and pulls the model. The model name is `OLLAMA_MODEL` in `setup.sh`.
- **`.zshrc`** — a `command -v ollama`-guarded block that exports **`OLLAMA_DEFAULT_MODEL`** (the single source of truth for the model name) and defines a small `ai` helper for one-shot terminal queries (`ai "explain this regex …"`). No-ops cleanly where Ollama isn't installed, like the other tool blocks.
- **Neovim** — the actual chat/inline integration is [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim), configured with an **Ollama adapter** pointed at `http://localhost:11434` and the model from `$OLLAMA_DEFAULT_MODEL`. **That config lives in the separate nvim repo** (see [Neovim](#neovim)), not here — these dotfiles only own the install + the env-var handoff.

Ollama serves an OpenAI-compatible API on `localhost:11434`. The server must be running for either the `ai` helper or codecompanion to work: on macOS start it with `ollama serve` (or `brew services start ollama`); on Linux the installer's systemd service handles it. To change the model, pull another (`ollama pull <name>`) and update `OLLAMA_DEFAULT_MODEL` — keep `OLLAMA_MODEL` in `setup.sh` and the nvim adapter in sync.

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
- https://ollama.com
- https://github.com/olimorris/codecompanion.nvim
- https://github.com/tmux-plugins/tpm
- https://github.com/junegunn/fzf
- https://github.com/sharkdp/bat
- https://www.nerdfonts.com
- https://www.tmuxcheatsheet.com
