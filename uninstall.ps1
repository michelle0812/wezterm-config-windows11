# wezterm-config-windows11 反安裝腳本
#
# 用法：
#   .\uninstall.ps1         只還原 WezTerm / Windows Terminal 設定、刪掉 ~/.wezterm 與 symlink
#                           （保留 Node.js / Claude Code / git / GitHub CLI / WezTerm 本身）
#   .\uninstall.ps1 -Full   連同 bootstrap.ps1 安裝的 Node.js / Claude Code / git / GitHub CLI / WezTerm
#                           一起解除安裝，還原到接近全新機器的狀態，適合用來重測整個一鍵安裝流程
#
# 注意：-Full 會移除 git / gh / Node.js 這類通用開發工具，
# 如果這台機器上還有其他專案依賴它們，請不要用 -Full。

param(
	[switch]$Full
)

if ($Full) {
	$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	if (-not $isAdmin) {
		Write-Host "==> -Full 需要系統管理員權限才能解除安裝 GitHub CLI / Node.js 這類系統層級套件，重新以系統管理員身分啟動中...（請在跳出的 UAC 視窗按「是」）"
		Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path, "-Full"
		exit
	}
}

$ErrorActionPreference = "Continue"

$TargetLua = "$env:USERPROFILE\.wezterm.lua"
$TargetDir = "$env:USERPROFILE\.wezterm"
$WtSettingsPaths = @(
	"$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
	"$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

Write-Host "===== 還原 Windows Terminal 設定 ====="
foreach ($settingsPath in $WtSettingsPaths) {
	if (Test-Path $settingsPath) {
		$dir = Split-Path $settingsPath -Parent
		$leaf = Split-Path $settingsPath -Leaf
		$backups = Get-ChildItem -Path $dir -Filter "$leaf.bak.*" -ErrorAction SilentlyContinue | Sort-Object Name
		if ($backups) {
			$earliest = $backups[0]
			Copy-Item $earliest.FullName $settingsPath -Force
			Write-Host "==> 已還原成最早的備份: $($earliest.Name)"
			$backups | Remove-Item -Force
			Write-Host "==> 已清掉所有備份檔"
		} else {
			Write-Host "==> $settingsPath 沒有備份，略過"
		}
	}
}

Write-Host "===== 還原 Tabby 設定 ====="
$TabbyConfigPath = "$env:APPDATA\tabby\config.yaml"
if (Test-Path $TabbyConfigPath) {
	$dir = Split-Path $TabbyConfigPath -Parent
	$leaf = Split-Path $TabbyConfigPath -Leaf
	$backups = Get-ChildItem -Path $dir -Filter "$leaf.bak.*" -ErrorAction SilentlyContinue | Sort-Object Name
	if ($backups) {
		$earliest = $backups[0]
		Copy-Item $earliest.FullName $TabbyConfigPath -Force
		Write-Host "==> 已還原成最早的備份: $($earliest.Name)"
		$backups | Remove-Item -Force
		Write-Host "==> 已清掉所有備份檔"
	} else {
		Write-Host "==> $TabbyConfigPath 沒有備份，略過（可能是全新安裝，直接刪除）"
		Remove-Item $TabbyConfigPath -Force -ErrorAction SilentlyContinue
	}
}

Write-Host "===== 還原開始選單「Windows PowerShell」捷徑的起始位置 ====="
$startMenuShortcuts = @(
	"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk",
	"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86).lnk"
)
$wshShell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in $startMenuShortcuts) {
	if (Test-Path $shortcutPath) {
		$shortcut = $wshShell.CreateShortcut($shortcutPath)
		if ($shortcut.WorkingDirectory) {
			$shortcut.WorkingDirectory = ""
			$shortcut.Save()
			Write-Host "==> 已清空起始位置: $shortcutPath"
		}
	}
}

Write-Host "===== 移除 symlink ~/.wezterm.lua ====="
if (Test-Path $TargetLua) {
	Remove-Item $TargetLua -Force
	Write-Host "==> 已刪除 $TargetLua"
}
Get-ChildItem "$env:USERPROFILE" -Filter ".wezterm.lua.bak.*" -Force -ErrorAction SilentlyContinue | ForEach-Object {
	Remove-Item $_.FullName -Force
	Write-Host "==> 已刪除舊備份: $($_.Name)"
}

Write-Host "===== 刪除 clone 的 repo (~/.wezterm) ====="
if (Test-Path $TargetDir) {
	if ((Get-Location).Path -like "$TargetDir*") {
		Write-Host "==> 目前所在目錄在 $TargetDir 裡面，Windows 無法刪除正在使用中的資料夾，先切換到 $env:USERPROFILE"
		Set-Location $env:USERPROFILE
	}
	Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
	if (Test-Path $TargetDir) {
		Write-Warning "刪除 $TargetDir 失敗，請關閉所有還開著這個資料夾的視窗/終端機後手動刪除"
	} else {
		Write-Host "==> 已刪除 $TargetDir"
	}
} else {
	Write-Host "==> $TargetDir 不存在，略過"
}

if ($Full) {
	Write-Host ""
	Write-Host "===== -Full：解除安裝 bootstrap.ps1 裝的工具 ====="

	Write-Host "-- WezTerm --"
	winget uninstall --id wez.wezterm -e --silent --accept-source-agreements
	Remove-Item "$env:LOCALAPPDATA\wezterm" -Recurse -Force -ErrorAction SilentlyContinue

	Write-Host "-- Tabby --"
	winget uninstall --id Eugeny.Tabby -e --silent --accept-source-agreements

	Write-Host "-- Claude Code (npm 套件) --"
	if (Get-Command npm -ErrorAction SilentlyContinue) {
		npm uninstall -g @anthropic-ai/claude-code
	}

	Write-Host "-- GitHub CLI（先登出再解除安裝）--"
	if (Get-Command gh -ErrorAction SilentlyContinue) {
		gh auth logout --hostname github.com 2>$null
	}
	winget uninstall --id GitHub.cli -e --silent --accept-source-agreements

	Write-Host "-- git --"
	winget uninstall --id Git.Git -e --silent --accept-source-agreements

	Write-Host "-- Node.js --"
	winget uninstall --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements

	Write-Host ""
	Write-Host "===== 完成，已還原成接近全新機器的狀態 ====="
	Write-Host "提醒：winget 解除安裝不一定會清掉每個工具在使用者層級留下的殘留設定/快取；"
	Write-Host "如果要 100% 乾淨重測，最保險的方式還是用全新的 VM 或映像檔。"
	Write-Host "建議安裝解除完成後，開一個新的終端機視窗，確認 node/claude/git/gh/wezterm 都抓不到指令了；"
	Write-Host "Tabby 沒有指令列工具，改用「設定」-「應用程式」確認清單裡已經沒有 Tabby。"
} else {
	Write-Host ""
	Write-Host "===== 完成（只清了 WezTerm/Windows Terminal/Tabby 設定與 repo） ====="
	Write-Host "如果也要移除 Node.js / Claude Code / git / gh / WezTerm / Tabby 本身，請執行：.\uninstall.ps1 -Full"
}
