#requires -Version 7.0
<#
  setup.ps1 — Windows counterpart to setup.sh (WORK VM, native PowerShell).

  Copies/links the PowerShell profile and shared config files into place, and
  (optionally) installs the CLI tools via winget.

  Usage:
    pwsh -File windows\setup.ps1              # link profile + configs only
    pwsh -File windows\setup.ps1 -Winget      # also install tools via winget
    pwsh -File windows\setup.ps1 -Work        # also link the work op template

  Notes:
    - WSL is assumed blocked on this VM, so this is native PowerShell only.
    - Symlinks on Windows need either Developer Mode on or an elevated shell;
      if mklink-style links fail, the script falls back to copying (and warns
      that repo edits then won't propagate until you re-run).
    - UNTESTED on Windows from the authoring machine (a Mac). Review before use.
#>
[CmdletBinding()]
param(
  [switch]$Winget,
  [switch]$Work
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Repo root = parent of this script's folder.
$Repo = Split-Path -Parent $PSScriptRoot

# Link (or copy) a repo file to a destination, backing up an existing real file.
function Link-Dotfile {
  param([string]$Source, [string]$Dest)

  $src = Join-Path $Repo $Source
  if (-not (Test-Path $src)) { Write-Host "  ! skip  $Source (missing in repo)"; return }

  $destDir = Split-Path -Parent $Dest
  if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

  # Already the correct symlink?
  $existing = Get-Item $Dest -ErrorAction SilentlyContinue
  if ($existing -and $existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq (Resolve-Path $src).Path) {
    Write-Host "  = ok    $Dest"; return
  }
  # Back up an existing real file.
  if (Test-Path $Dest) { Move-Item $Dest "$Dest.bak" -Force; Write-Host "  ~ backup $Dest -> $Dest.bak" }

  try {
    New-Item -ItemType SymbolicLink -Path $Dest -Target (Resolve-Path $src).Path -ErrorAction Stop | Out-Null
    Write-Host "  + link  $Dest -> $src"
  } catch {
    Copy-Item $src $Dest -Force
    Write-Host "  + copy  $Dest (symlink failed — enable Developer Mode for live links; re-run after repo edits)"
  }
}

# CLI tools — winget IDs. Mirrors the macOS/Linux tool set.
$WingetPackages = @(
  'JanDeDobbeleer.OhMyPosh',   # oh-my-posh
  'Neovim.Neovim',             # nvim
  'Git.Git',                   # git
  'junegunn.fzf',              # fzf
  'sharkdp.bat',               # bat
  'eza-community.eza',         # eza
  'ajeetdsouza.zoxide',        # zoxide
  'sharkdp.fd',                # fd
  'BurntSushi.ripgrep.MSVC',   # ripgrep
  'GitHub.cli',                # gh
  'AgileBits.1Password.CLI',   # op
  'fullstorydev.grpcurl',      # grpcurl
  'Volta.Volta'                # volta
)

if ($Winget) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'winget not found — install "App Installer" from the Microsoft Store, or use -Winget:$false and install manually.'
    exit 1
  }
  Write-Host 'Installing CLI tools via winget...'
  foreach ($pkg in $WingetPackages) {
    Write-Host "  winget install $pkg"
    winget install --exact --id $pkg --accept-source-agreements --accept-package-agreements --silent
  }
  # PSReadLine ships with PS7; PSFzf is optional but enables the fzf key bindings.
  if (-not (Get-Module -ListAvailable PSFzf)) {
    Install-Module PSFzf -Scope CurrentUser -Force -AcceptLicense
  }
  Write-Host ''
}

Write-Host "Linking dotfiles from $Repo"

# PowerShell profile (all-hosts, current user).
Link-Dotfile 'windows\Microsoft.PowerShell_profile.ps1' $PROFILE.CurrentUserAllHosts

# Shared, OS-portable config files.
Link-Dotfile '.jonathanhicks.omp.json' (Join-Path $HOME '.jonathanhicks.omp.json')
Link-Dotfile 'config\bat\config'       (Join-Path $HOME '.config\bat\config')
Link-Dotfile 'config\git\ignore'       (Join-Path $HOME '.config\git\ignore')

# Work-only: the op run template for Artifactory/Nexus (see .zshrc notes).
if ($Work) {
  Link-Dotfile 'config\op\artifactory.env' (Join-Path $HOME '.config\op\artifactory.env')
}

Write-Host ''
Write-Host 'Done. Remaining manual steps:'
Write-Host '  - Restart pwsh (or: . $PROFILE) to load the profile'
Write-Host '  - Install a Nerd Font and set it in Windows Terminal so prompt/eza glyphs render'
Write-Host '  - Neovim config is a separate repo (clone it into ~\AppData\Local\nvim)'
Write-Host '  - 1Password: enable Settings -> Developer -> Integrate with 1Password CLI'
