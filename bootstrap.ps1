# wezterm-config-windows11 一鍵安裝腳本
# 用法（在全新的 Windows 11 機器上，開一個 PowerShell 視窗貼上這行執行）：
#
#   irm https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1 | iex
#
# 會自動：
#   1. 確認/安裝 Node.js、Claude Code、git、GitHub CLI（已安裝的會自動略過）
#   2. Clone（或更新）這個 repo 到 ~/.wezterm
#   3. 執行 install.ps1，安裝 WezTerm、套用 WezTerm / Windows Terminal 設定
#
# 因為建立 symlink 需要系統管理員權限，這支腳本一開始會自動用系統管理員身分重新啟動自己（會跳出一次 UAC 視窗）。

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/michelle0812/wezterm-config-windows11.git"
$BootstrapUrl = "https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1"
$TargetDir = "$env:USERPROFILE\.wezterm"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "==> 需要系統管理員權限才能建立 symlink，重新以系統管理員身分啟動中...（請在跳出的 UAC 視窗按「是」）"
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
		Write-Host "==> $CheckCommand 已安裝，略過"
		return
	}
	Write-Host "==> 安裝 $Id ..."
	winget install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements
	Refresh-Path
}

Write-Host "===== Step 1/6：確認 Node.js ====="
Ensure-WingetPackage -Id "OpenJS.NodeJS.LTS" -CheckCommand "node"

Write-Host "===== Step 2/6：確認 Claude Code ====="
if (Get-Command claude -ErrorAction SilentlyContinue) {
	Write-Host "==> claude 已安裝，略過"
} else {
	Write-Host "==> 安裝 Claude Code (npm install -g @anthropic-ai/claude-code) ..."
	npm install -g @anthropic-ai/claude-code
	Refresh-Path
}

Write-Host "===== Step 3/6：確認 git ====="
Ensure-WingetPackage -Id "Git.Git" -CheckCommand "git"

Write-Host "===== Step 4/6：確認 GitHub CLI ====="
Ensure-WingetPackage -Id "GitHub.cli" -CheckCommand "gh"

Write-Host "===== Step 5/6：取得設定檔 ====="
if (Test-Path (Join-Path $TargetDir ".git")) {
	Write-Host "==> $TargetDir 已經是 git repo，執行 git pull 更新"
	Push-Location $TargetDir
	git pull
	Pop-Location
} elseif (Test-Path $TargetDir) {
	Write-Host "==> $TargetDir 已存在但不是 git repo，接上遠端並強制同步成最新版本"
	Push-Location $TargetDir
	git init
	git remote remove origin 2>$null
	git remote add origin $RepoUrl
	git fetch origin main
	git reset --hard origin/main
	Pop-Location
} else {
	Write-Host "==> Clone 到 $TargetDir"
	git clone $RepoUrl $TargetDir
}

Write-Host "===== Step 6/6：套用 WezTerm / Windows Terminal 設定 ====="
& "$TargetDir\install.ps1"

Write-Host ""
Write-Host "===== 全部安裝完成！請重新開啟 WezTerm / Windows Terminal 查看效果 ====="
