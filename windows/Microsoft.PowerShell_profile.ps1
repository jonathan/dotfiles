# PowerShell profile — Windows counterpart to .zshrc (WORK VM, single account).
#
# Installs to: $PROFILE.CurrentUserAllHosts
#   (usually ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 for PS7)
# Apply changes: . $PROFILE   (or open a new pwsh session)
#
# This is a WORK VM with one set of accounts — so unlike the macOS .zshrc there
# are NO personal/work multi-account wrappers (no gh switcher, no opp/opw split).
# Everything is guarded so a missing tool degrades gracefully, matching the
# `command -v` pattern in .zshrc.

# --- helper: is a command available? (mirrors `command -v` guards) -----------
function Test-HasCommand { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# --- Editor ------------------------------------------------------------------
$env:EDITOR = 'nvim'

# --- PSReadLine: the native equivalent of zsh-autosuggestions +
#     fast-syntax-highlighting + history-substring-search (all built in). ------
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin   # fish-like autosuggestions
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -EditMode Vi                         # matches `bindkey -v`
  # Up/Down do prefix/substring history search (like history-substring-search).
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# --- Modern CLI tools (same set as .zshrc), each guarded ---------------------
# eza -> ls
if (Test-HasCommand eza) {
  function ls { eza --group-directories-first --icons --git @args }
  function ll { eza -lFh --group-directories-first --icons --git @args }
  function la { eza -a --group-directories-first --icons --git @args }
  function lt { eza --tree --level=2 --icons @args }
}

# zoxide -> cd (z <partial>)
if (Test-HasCommand zoxide) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }

# fzf: key bindings + completion (PSFzf if present)
if ((Test-HasCommand fzf) -and (Get-Module -ListAvailable PSFzf)) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
# fd as fzf's source (matches FZF_DEFAULT_COMMAND), if present
if (Test-HasCommand fd) {
  $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
  $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
  $env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --follow --exclude .git'
}
# Dracula fzf colors (same palette as .zshrc)
$env:FZF_DEFAULT_OPTS = '--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

# bat: nothing to alias (Windows ships no `cat` clash); just ensure config theme.
# (config lives at ~\.config\bat\config, linked by setup.ps1)

# --- Aliases (mirrors the .zshrc set, minus Unix-only ones) ------------------
if (Test-HasCommand nvim) { Set-Alias vi nvim }
function gts { git tag --sort version:refname @args }
function gbc { git checkout -b @args }

# --- HTTP / gRPC helpers (PowerShell ports of the .zshrc functions) ----------
# Pretty-print JSON on the pipeline via bat if present, else pass through.
function ConvertOut-PrettyJson {
  if (Test-HasCommand bat) { $input | bat --language=json --style=plain --paging=never }
  else { $input }
}
if (Test-HasCommand curl.exe) {
  # curlj <url> — GET + pretty-print JSON. (curl.exe = real curl, not the PS alias.)
  function curlj { curl.exe -fsS @args | ConvertOut-PrettyJson }
  function curlh { curl.exe -sS -D - -o NUL @args }
  function curlt { curl.exe -sS -o NUL -w "dns:`t%{time_namelookup}s`nconnect:`t%{time_connect}s`ntls:`t%{time_appconnect}s`nttfb:`t%{time_starttransfer}s`ntotal:`t%{time_total}s`n" @args }
}
if (Test-HasCommand grpcurl) {
  function gcurl  { grpcurl -plaintext @args }
  function gcurld { param($GHost,$Method,$Body='') grpcurl -plaintext -d $Body $GHost $Method }
  function gcls   { param($GHost) grpcurl -plaintext $GHost list }
  function gcdesc { param($GHost,$Symbol='') grpcurl -plaintext $GHost describe $Symbol }
}

# --- 1Password CLI (op) — WORK account only ----------------------------------
# Single account on this VM, so no personal/work split. If `op account list`
# shows one account, bare `op` needs no --account.
if (Test-HasCommand op) {
  # openv <env-file> -- <cmd...> : run a command with secrets from an op env-file
  # of op:// references, resolved only for that command (op run). Generic.
  function openv {
    param([string]$EnvFile)
    $rest = $args
    op run --env-file=$EnvFile -- @rest
  }
  # artenv <cmd...> : work Artifactory/Nexus secrets (template under ~\.config\op).
  function artenv { openv "$HOME\.config\op\artifactory.env" @args }

  # op completion
  if ((op completion powershell 2>$null)) { op completion powershell | Out-String | Invoke-Expression }
}

# --- Prompt: oh-my-posh with the shared Dracula theme ------------------------
if (Test-HasCommand oh-my-posh) {
  oh-my-posh init pwsh --config "$HOME\.jonathanhicks.omp.json" | Invoke-Expression
}

# --- Machine-local extras (secrets / per-VM config), not tracked -------------
if (Test-Path "$HOME\.env_vars.ps1")  { . "$HOME\.env_vars.ps1" }
if (Test-Path "$HOME\.bootstrap.ps1") { . "$HOME\.bootstrap.ps1" }
