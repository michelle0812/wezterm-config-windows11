# Windows 安裝腳本：把 ~/.wezterm.lua symlink 到這個 repo 的 loader.lua
$RepoDir = Split-Path -Parent $PSScriptRoot
$Target = "$env:USERPROFILE\.wezterm.lua"
$Source = "$RepoDir\loader.lua"

if (Test-Path $Target) {
	$Item = Get-Item $Target -Force
	if ($Item.LinkType -ne "SymbolicLink") {
		$Backup = "$Target.bak.$(Get-Date -Format yyyyMMddHHmmss)"
		Move-Item $Target $Backup
		Write-Host "既有設定已備份到 $Backup"
	} else {
		Remove-Item $Target -Force
	}
}

New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
Write-Host "已建立 symlink: $Target -> $Source"
Write-Host "若出現權限錯誤，請在系統設定開啟「開發人員模式」，或用系統管理員權限重跑此腳本"
