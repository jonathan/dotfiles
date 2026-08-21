# tmux cheatsheet

A re-onboarding reference for **this repo's** [`.tmux.conf`](.tmux.conf) — these are the
actual bindings configured here, not generic defaults. The prefix is remapped to
**`C-a`**, written below as **`<P>`**. So "`<P> |`" means: press `Ctrl-a`, release,
then press `|`.

Why bother: a new tmux window/pane is near-instant and doesn't spawn a new terminal
GPU surface, so it's a faster replacement for native terminal tabs — and sessions
**persist** across closing the terminal, GPU restarts, even reboots (via
[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)).

## Sessions — the killer feature (persist across reboots)

| Action | Command (in shell) |
|---|---|
| Start a named session | `tmux new -s work` |
| Detach (leave it running) | `<P> d` |
| Re-attach later | `tmux attach -t work` (or `tmux a`) |
| List sessions | `tmux ls` |
| Switch between sessions | `<P> s` (visual picker) |
| **Save** session state | `<P> Ctrl-s` *(resurrect — survives reboot)* |
| **Restore** after reboot | `<P> Ctrl-r` *(resurrect; restores Vim sessions too)* |

## Windows (your "tabs" — instant, no GPU surface)

Numbering starts at **1** (`base-index 1`).

| Action | Binding |
|---|---|
| New window | `<P> c` |
| Next / previous | `<P> n` / `<P> p` |
| Next / previous (tab motion, no prefix) | `⌘-Shift-]` / `⌘-Shift-[` on macOS *(Ghostty rewrites these to `M-}` / `M-{`; Super-Shift-brackets on Linux)* |
| Jump to window N | `<P> 1` … `<P> 9` |
| **Toggle last window** | `<P> Ctrl-b` *(custom bind)* |
| Rename window | `<P> ,` |
| Close window | `<P> &` |

## Splits (panes) — open in the current directory

Splits inherit the active pane's cwd (`-c "#{pane_current_path}"`), so no re-`cd`.

| Action | Binding |
|---|---|
| Split **vertical** (left/right) | `<P> \|` |
| Split **horizontal** (top/bottom) | `<P> -` |
| **Move between panes** | `Ctrl-h/j/k/l` — **no prefix!** |
| Close pane | `<P> x` |
| Zoom pane fullscreen (toggle) | `<P> z` |
| Resize pane | `<P>` then `Ctrl-↑/↓/←/→` — hold `Ctrl`, tap arrows (repeatable) |

> The `Ctrl-h/j/k/l` navigation is the best-configured, most-underused feature here:
> via [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) it moves
> between tmux panes *and* Neovim splits with the **same keys, no prefix**. Inside nvim,
> `Ctrl-l` moves to the split on the right whether that's a Vim window or a tmux pane.
> Retrain your fingers on this first.

## Copy mode (Vi-style — `mode-keys vi`)

| Action | Binding |
|---|---|
| Enter copy/scroll mode | `<P> [` |
| Move around | `h j k l`, `/` to search (Vim keys) |
| Start selection | `v` |
| **Yank → system clipboard** | `y` *(piped to the OS clipboard command — `pbcopy` on macOS)* |
| Paste tmux buffer | `<P> v` *(custom bind)* |
| Exit copy mode | `q` |

Mouse also works (`mouse on`): scroll to enter copy mode, drag to select → auto-copies
to the system clipboard.

## Vi keys everywhere

Both of tmux's vi/emacs-selectable modes are set to **vi**:

- **`mode-keys vi`** — copy/scroll mode (the table above).
- **`status-keys vi`** — the command prompt (`<P> :`): vi editing keys, not emacs.

> Gotcha: `tmux-sensible` unconditionally force-sets `status-keys emacs`, and tpm runs
> near the bottom of `.tmux.conf` — so `status-keys vi` is re-asserted *after* the tpm
> `run` line to win. Don't move it back up top or the emacs default silently returns.

Everything else (pane/window management) is prefix-based by tmux's design — that's not a
vi/emacs setting, so there's nothing further to switch there.

## Config reload

After editing `~/.tmux.conf`: `<P> r` (bound to `source-file`).

## Suggested re-onboarding path

Don't learn all 30 bindings at once:

1. **Day 1:** Live in one session. Use `<P> c` for windows and `<P> 1/2/3` to jump.
   That alone replaces slow terminal tabs.
2. **Day 2:** Add splits (`<P> |`, `<P> -`) and the no-prefix `Ctrl-h/j/k/l` nav into Neovim.
3. **Day 3:** Adopt detach/attach (`<P> d` / `tmux a`). Once you trust persistence,
   you stop closing your terminal at all.

## Plugins

Managed by [tpm](https://github.com/tmux-plugins/tpm) (the `@plugin` lines at the bottom
of `.tmux.conf`). Installed: tmux-sensible, tmux-resurrect, vim-tmux-navigator, and a
personal fork of dracula/tmux (`jonathan/tmux` — upstream's `mac-player` script fails to
compile if any one of its four hardcoded apps isn't installed; see the comment above the
`@plugin` line in `.tmux.conf`). If the resurrect saves/restores or other plugins don't
respond, install them once with `<P> I`, or reload with `<P> r`.
