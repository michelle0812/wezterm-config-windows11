# wezterm-config-windows11 one-click bootstrap script
# Usage (on a fresh Windows 11 machine, open PowerShell and paste this line):
#
#   irm https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1 | iex
#
# This script must stay plain ASCII (no non-English characters, no BOM).
# It is fetched over HTTP via Invoke-RestMethod and piped into Invoke-Expression;
# Windows PowerShell 5.1 leaves a leading UTF-8 BOM character in that string,
# which breaks script parsing when a BOM-prefixed file is used here. Every other
# script in this repo is only ever run as a local file (after git clone), so it
# keeps a BOM + Chinese text for correct parsing there instead.
#
# What this does:
#   1. Ensure Node.js, Claude Code, git, GitHub CLI are installed (skips if already present)
#   2. Clone (or update) this repo into ~/.wezterm
#   3. Run install.ps1 to install WezTerm and apply WezTerm / Windows Terminal settings
#
# Creating the symlink requires administrator rights, so this script relaunches
# itself elevated first (one UAC prompt).

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/michelle0812/wezterm-config-windows11.git"
$BootstrapUrl = "https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1"
$TargetDir = "$env:USERPROFILE\.wezterm"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "==> Administrator rights are required to create the symlink. Relaunching elevated (approve the UAC prompt)..."
	Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm $BootstrapUrl | iex"
	exit
}

function Refresh-Path {
	$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
	$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
	$env:Path = "$machinePath;$userPath"
}

function Ensure-WingetPackage {
	param(
		[Parameter(Mandatory)] [string]$Id,
		[Parameter(Mandatory)] [string]$CheckCommand
	)
	if (Get-Command $CheckCommand -ErrorAction SilentlyContinue) {
		Write-Host "==> $CheckCommand already installed, skipping"
		return
	}
	Write-Host "==> Installing $Id ..."
	winget install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements
	Refresh-Path
}

Write-Host "===== Step 1/6: Node.js ====="
Ensure-WingetPackage -Id "OpenJS.NodeJS.LTS" -CheckCommand "node"

Write-Host "===== Step 2/6: Claude Code ====="
if (Get-Command claude -ErrorAction SilentlyContinue) {
	Write-Host "==> claude already installed, skipping"
} else {
	Write-Host "==> Installing Claude Code (npm install -g @anthropic-ai/claude-code) ..."
	npm install -g @anthropic-ai/claude-code
	Refresh-Path
}

Write-Host "===== Step 3/6: git ====="
Ensure-WingetPackage -Id "Git.Git" -CheckCommand "git"

Write-Host "===== Step 4/6: GitHub CLI ====="
Ensure-WingetPackage -Id "GitHub.cli" -CheckCommand "gh"

Write-Host "===== Step 5/6: Fetch config ====="
if (Test-Path (Join-Path $TargetDir ".git")) {
	Write-Host "==> $TargetDir is already a git repo, running git pull"
	Push-Location $TargetDir
	git pull
	Pop-Location
} elseif (Test-Path $TargetDir) {
	Write-Host "==> $TargetDir exists but is not a git repo, attaching remote and force-syncing"
	Push-Location $TargetDir
	git init
	git remote remove origin 2>$null
	git remote add origin $RepoUrl
	git fetch origin main
	git reset --hard origin/main
	Pop-Location
} else {
	Write-Host "==> Cloning into $TargetDir"
	git clone $RepoUrl $TargetDir
}

Write-Host "===== Step 6/6: Apply WezTerm / Windows Terminal settings ====="
& "$TargetDir\install.ps1"

Write-Host ""
Write-Host "===== All done! Reopen WezTerm / Windows Terminal to see the changes ====="
