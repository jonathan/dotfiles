# Preferred CLI tools

<!-- Tracked in the dotfiles repo as claude/rules/cli-tools.md and symlinked to
     ~/.claude/rules/cli-tools.md by setup.sh. User-level rules in ~/.claude/rules/
     load into every session automatically, in every project.

     This deliberately does NOT live in ~/.claude/CLAUDE.md: that file is wholly
     managed by DevBar (devbar:optimized-tools markers) and gets regenerated, so
     edits there are lost. DevBar already covers rg / fd / sd / ast-grep / jq /
     bat there; this file covers everything else. -->

These are installed on my machines and preferred over the classics. **Call them by
their real binary name** — my shell aliases (`lg`, `dft`, `kctx`, `man`→`batman`,
`top`→`btop`) are defined in `~/.zshrc` for interactive use and are generally NOT
available in the Bash tool's shell, so don't rely on them.

Each is guarded by `command -v` in `~/.zshrc`, so on a machine where one isn't
installed the classic tool is still what's there — check before assuming.

- `yq` to query and transform **YAML/TOML/XML** — same query language as `jq`.
  Use it for helm values, k8s manifests, `.strata.yml`, `*.toml`. Don't reach for
  `grep`/`sed` on structured YAML, and don't pipe YAML into `jq`.
  This is the Go `mikefarah/yq`, not the Python wrapper of the same name.
  `-i` edits in place; `-o=json` converts. When reading TOML, pass the output
  format explicitly (`-p=toml -o=toml`, or `-p=toml -oy`) — `-p=toml` alone emits
  a WARN line on stderr about the default output format.
- `difft` (difftastic) for **structural/AST** diffs, when the question is "did the
  logic change?" rather than "which lines changed?" — it reports "No syntactic
  changes" for pure reformatting/reindentation. To diff git state:
  `GIT_EXTERNAL_DIFF=difft git diff --ext-diff [revspec]`. Caveat: `--stat`
  bypasses the external differ and falls back to a line-based stat.
  For normal line diffs, plain `git diff` is right — it's already configured to
  use `delta` as the pager.
- `dust` instead of `du` to find what's consuming disk (sorted tree; `-d1` for
  one level).
- `procs` instead of `ps` for a readable process list (`procs <pattern>` filters).
- `batman` instead of `man`, and `batgrep`/`batdiff` (from bat-extras) when
  highlighted output helps. Plain `man` is fine too.
- `hyperfine` instead of hand-rolled `time` loops for **any** before/after
  performance claim — it does warmup runs and reports mean ± σ, e.g.
  `hyperfine --warmup 3 'cmd'`. Prefer it over reporting a single `time` result.
  To compare two commands, put `-n` before each:
  `hyperfine -n before 'cmd1' -n after 'cmd2'` (prints a "N times faster" summary).
  If the σ overlaps the difference, say the result is within noise rather than
  claiming a speedup.
- `stern` to tail logs across **multiple** pods matching a regex, where
  `kubectl logs` handles only one. Always pass `--no-follow` (and usually
  `--tail=N`) in a tool call — the default follows the stream and will hang.

## Interactive tools — don't launch these in a tool call

`lazygit`, `btop`, `k9s`, and `procs --watch` are full-screen TUIs that never exit
on their own; launching one in a non-interactive shell hangs the call. Same for
`stern` without `--no-follow`. If a TUI is genuinely the best answer, tell me to
run it myself rather than invoking it.

## Not aliased on purpose

`dust` and `procs` are installed but deliberately NOT aliased over `du`/`ps` in my
shell, because their flags are incompatible with the standard invocations. So
`du -sh *` and `ps aux` still mean the real `du`/`ps` and remain correct — use
those when you specifically want classic behavior or POSIX-portable output.
