# wezterm-config-windows11 一鍵安裝腳本（需先手動完成 git/gh 安裝與登入，見 README.md）
# 用法：在 clone 好這個 repo 之後，於 repo 根目錄執行 .\install.ps1
$ErrorActionPreference = "Stop"

# 把完整終端機輸出記錄到 $HOME，方便事後回顧安裝歷程。
# 如果外層已經有 transcript 在跑（例如被 bootstrap.ps1 呼叫，會設定 WEZTERM_LOG_ACTIVE），
# 就不要另外再開一份，讓外層的紀錄繼續就好，不會兩邊各寫一份重複的 log
# （Start-Transcript 巢狀呼叫不會擲錯，只會悄悄開第二份獨立的，所以不能靠 try/catch 判斷）
$WeztermLogStartedHere = $false
if ($env:WEZTERM_LOG_ACTIVE -ne "1") {
	$LogPath = Join-Path $env:USERPROFILE ("wezterm-install-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
	try {
		Start-Transcript -Path $LogPath -Append -ErrorAction Stop | Out-Null
		$WeztermLogStartedHere = $true
		$env:WEZTERM_LOG_ACTIVE = "1"
		Write-Host "==> 完整記錄會存到 $LogPath"
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
			[string]$CheckCommand,
			[string]$CheckPath
		)
		if ($CheckCommand -and (Get-Command $CheckCommand -ErrorAction SilentlyContinue)) {
			Write-Host "==> $CheckCommand 已安裝，略過"
			return
		}
		if ($CheckPath -and (Test-Path $CheckPath)) {
			Write-Host "==> 已安裝於 $CheckPath，略過"
			return
		}
		Write-Host "==> 安裝 $Id ..."
		winget install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements
		Refresh-Path
	}

	Write-Host "===== Step 1/5：確認 Git ====="
	Ensure-WingetPackage -Id "Git.Git" -CheckCommand "git"

	Write-Host "===== Step 2/5：確認 GitHub CLI ====="
	Ensure-WingetPackage -Id "GitHub.cli" -CheckCommand "gh"

	Write-Host "===== Step 3/5：安裝 WezTerm ====="
	Ensure-WingetPackage -Id "wez.wezterm" -CheckCommand "wezterm"
	Refresh-Path

	Write-Host "===== Step 4/5：安裝 Tabby ====="
	# Tabby 不會把指令列工具註冊進 PATH，用安裝路徑判斷是否已安裝
	Ensure-WingetPackage -Id "Eugeny.Tabby" -CheckPath "$env:LOCALAPPDATA\Programs\Tabby\Tabby.exe"

	Write-Host "===== Step 5/5：套用設定 ====="
	Write-Host "-- WezTerm (symlink ~/.wezterm.lua) --"
	& "$PSScriptRoot\bin\setup.ps1"

	Write-Host "-- Windows Terminal / PowerShell --"
	& "$PSScriptRoot\bin\setup-windows-terminal.ps1"

	Write-Host "-- Tabby --"
	& "$PSScriptRoot\bin\setup-tabby.ps1"

	Write-Host ""
	Write-Host "===== 安裝完成 ====="
	Write-Host "如果 gh 還沒登入，請執行：gh auth login"
	Write-Host "如果 symlink 建立失敗（權限錯誤），請開啟「開發人員模式」或用系統管理員權限重跑此腳本"
} finally {
	if ($WeztermLogStartedHere) {
		Stop-Transcript | Out-Null
		Remove-Item Env:\WEZTERM_LOG_ACTIVE -ErrorAction SilentlyContinue
		$logFile = Get-Item $LogPath -ErrorAction SilentlyContinue
		if (-not $logFile -or $logFile.Length -lt 200) {
			Write-Warning "log 檔案 $LogPath 看起來是空的或寫入不完整，這次的紀錄可能遺失了（安裝本身不受影響）"
		}
	}
}
