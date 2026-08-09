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
#
# Logging is opt-in and off by default. Since this script is normally run via
# "irm ... | iex" (a plain expression, not a parameterized script invocation),
# a -Log switch parameter would not be reachable from that one-liner, so the
# opt-in is done through an env var instead:
#   $env:WEZTERM_LOG = "1"; irm https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1 | iex
# Running this file locally after cloning also accepts a real -Log switch.

param(
	[switch]$Log
)

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/michelle0812/wezterm-config-windows11.git"
$BootstrapUrl = "https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1"
$TargetDir = "$env:USERPROFILE\.wezterm"
$ShouldLog = $Log -or ($env:WEZTERM_LOG -eq "1")

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "==> Administrator rights are required to create the symlink. Relaunching elevated (approve the UAC prompt)..."
	$relaunchCommand = if ($ShouldLog) { "`$env:WEZTERM_LOG='1'; irm $BootstrapUrl | iex" } else { "irm $BootstrapUrl | iex" }
	Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $relaunchCommand
	Write-Host "==> Continuing in the new elevated window; this one is done and can stay open."
	return
}

# Record the full console output to $HOME so the install history can be reviewed later.
# install.ps1 (invoked in Step 6 below) checks WEZTERM_LOG_ACTIVE and skips starting its
# own transcript when it's already set, so the whole bootstrap + install run ends up as a
# single log instead of two overlapping ones (Start-Transcript does not error out when
# called while one is already active, it just quietly starts a second, independent one).
$WeztermLogStartedHere = $false
if ($ShouldLog) {
	$LogPath = Join-Path $env:USERPROFILE ("wezterm-install-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
	try {
		Start-Transcript -Path $LogPath -Append -ErrorAction Stop | Out-Null
		$WeztermLogStartedHere = $true
		$env:WEZTERM_LOG_ACTIVE = "1"
		Write-Host "==> Logging full output to $LogPath"
	} catch {}
}

try {
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
	& "$TargetDir\install.ps1" -Log:$ShouldLog

	Write-Host ""
	Write-Host "===== All done! Reopen WezTerm / Windows Terminal to see the changes ====="
} finally {
	if ($WeztermLogStartedHere) {
		Stop-Transcript | Out-Null
		Remove-Item Env:\WEZTERM_LOG_ACTIVE -ErrorAction SilentlyContinue
		$logFile = Get-Item $LogPath -ErrorAction SilentlyContinue
		if (-not $logFile -or $logFile.Length -lt 200) {
			Write-Warning "Log file $LogPath looks empty or incomplete; this run's log may be lost (the install itself is unaffected)"
		}
	}
}
