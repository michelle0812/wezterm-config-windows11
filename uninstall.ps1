# wezterm-config-windows11 反安裝腳本
#
# 用法：
#   .\uninstall.ps1   還原 WezTerm / Windows Terminal / Tabby 設定、刪掉 ~/.wezterm 與 symlink，
#                     並連同 bootstrap.ps1 安裝的 Node.js / Claude Code / git / GitHub CLI / WezTerm / Tabby
#                     一起解除安裝，還原到接近全新機器的狀態
#
# 注意：這會移除 git / gh / Node.js 這類通用開發工具，
# 如果這台機器上還有其他專案依賴它們，執行前請三思。

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "==> 需要系統管理員權限才能解除安裝 GitHub CLI / Node.js 這類系統層級套件，重新以系統管理員身分啟動中...（請在跳出的 UAC 視窗按「是」）"
	Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path
	Write-Host "==> 已在新的系統管理員視窗接手繼續，這個視窗可以繼續留著用"
	return
}

$ErrorActionPreference = "Continue"

# 把完整終端機輸出記錄到 $HOME，方便事後回顧反安裝歷程
$WeztermLogStartedHere = $false
$LogPath = Join-Path $env:USERPROFILE ("wezterm-uninstall-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
try {
	Start-Transcript -Path $LogPath -Append -ErrorAction Stop | Out-Null
	$WeztermLogStartedHere = $true
	Write-Host "==> 完整記錄會存到 $LogPath"
} catch {}

try {
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

	Write-Host ""
	Write-Host "===== 解除安裝 bootstrap.ps1 裝的工具 ====="

	Write-Host "-- WezTerm --"
	winget uninstall --id wez.wezterm -e --silent --accept-source-agreements
	Remove-Item "$env:LOCALAPPDATA\wezterm" -Recurse -Force -ErrorAction SilentlyContinue

	Write-Host "-- Tabby --"
	# Tabby 是「使用者層級」安裝，用 winget 在系統管理員權限下解除安裝會失敗
	# （"cannot be uninstalled when running with administrator privileges"），
	# 改成直接呼叫它自帶的解除安裝程式，靜默模式繞過這個範圍衝突
	$tabbyUninstaller = "$env:LOCALAPPDATA\Programs\Tabby\Uninstall Tabby.exe"
	if (Test-Path $tabbyUninstaller) {
		Start-Process -FilePath $tabbyUninstaller -ArgumentList "/S" -Wait
		Write-Host "==> 已執行 Tabby 解除安裝程式"
	} else {
		Write-Host "==> 找不到 $tabbyUninstaller，改用 winget（使用者層級套件在系統管理員權限下可能無法移除）"
		winget uninstall --id Eugeny.Tabby -e --silent --accept-source-agreements
	}

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
	Write-Host "建議解除完成後，開一個新的終端機視窗，確認 node/claude/git/gh/wezterm 都抓不到指令了；"
	Write-Host "Tabby 沒有指令列工具，改用「設定」-「應用程式」確認清單裡已經沒有 Tabby。"
} finally {
	if ($WeztermLogStartedHere) {
		Stop-Transcript | Out-Null
		$logFile = Get-Item $LogPath -ErrorAction SilentlyContinue
		if (-not $logFile -or $logFile.Length -lt 200) {
			Write-Warning "log 檔案 $LogPath 看起來是空的或寫入不完整，這次的紀錄可能遺失了（反安裝本身不受影響）"
		}
	}
}
