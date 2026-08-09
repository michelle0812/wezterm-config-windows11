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
	Remove-Item $TargetDir -Recurse -Force
	Write-Host "==> 已刪除 $TargetDir"
} else {
	Write-Host "==> $TargetDir 不存在，略過"
}

if ($Full) {
	Write-Host ""
	Write-Host "===== -Full：解除安裝 bootstrap.ps1 裝的工具 ====="

	Write-Host "-- WezTerm --"
	winget uninstall --id wez.wezterm -e --silent 2>$null
	Remove-Item "$env:LOCALAPPDATA\wezterm" -Recurse -Force -ErrorAction SilentlyContinue

	Write-Host "-- Claude Code (npm 套件) --"
	if (Get-Command npm -ErrorAction SilentlyContinue) {
		npm uninstall -g @anthropic-ai/claude-code 2>$null
	}

	Write-Host "-- GitHub CLI（先登出再解除安裝）--"
	if (Get-Command gh -ErrorAction SilentlyContinue) {
		gh auth logout --hostname github.com 2>$null
	}
	winget uninstall --id GitHub.cli -e --silent 2>$null

	Write-Host "-- git --"
	winget uninstall --id Git.Git -e --silent 2>$null

	Write-Host "-- Node.js --"
	winget uninstall --id OpenJS.NodeJS.LTS -e --silent 2>$null

	Write-Host ""
	Write-Host "===== 完成，已還原成接近全新機器的狀態 ====="
	Write-Host "提醒：winget 解除安裝不一定會清掉每個工具在使用者層級留下的殘留設定/快取；"
	Write-Host "如果要 100% 乾淨重測，最保險的方式還是用全新的 VM 或映像檔。"
	Write-Host "建議安裝解除完成後，開一個新的終端機視窗，確認 node/claude/git/gh/wezterm 都抓不到指令了。"
} else {
	Write-Host ""
	Write-Host "===== 完成（只清了 WezTerm/Windows Terminal 設定與 repo） ====="
	Write-Host "如果也要移除 Node.js / Claude Code / git / gh / WezTerm 本身，請執行：.\uninstall.ps1 -Full"
}
