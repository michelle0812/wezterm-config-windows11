# 把透明度 + Ctrl+T / Ctrl+W / Ctrl+1~9 快捷鍵合併進 Windows Terminal 的 Windows PowerShell profile
# 只會修改需要的欄位，不會整份覆蓋，執行多次結果一樣（idempotent）
$ErrorActionPreference = "Stop"

$candidatePaths = @(
	"$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
	"$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$settingsPath = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $settingsPath) {
	Write-Warning "找不到 Windows Terminal 的 settings.json，請先開一次 Windows Terminal 讓它產生預設設定檔，再重跑這個腳本"
	return
}

$backup = "$settingsPath.bak.$(Get-Date -Format yyyyMMddHHmmss)"
Copy-Item $settingsPath $backup
Write-Host "已備份原始設定到 $backup"

$json = Get-Content $settingsPath -Raw | ConvertFrom-Json

# 1) Windows PowerShell profile 透明度，比照 WezTerm 的 window_background_opacity = 0.9
$psProfile = $json.profiles.list | Where-Object { $_.commandline -match "WindowsPowerShell\\v1\.0\\powershell\.exe" } | Select-Object -First 1
if ($psProfile) {
	$psProfile | Add-Member -NotePropertyName opacity -NotePropertyValue 90 -Force
	$psProfile | Add-Member -NotePropertyName useAcrylic -NotePropertyValue $false -Force
} else {
	Write-Warning "找不到 Windows PowerShell 這個 profile，略過透明度設定"
}

# 2) 快捷鍵：Ctrl+T 開新分頁、Ctrl+W 關閉分頁、Ctrl+1~8 切換分頁（有對應的內建 id）
$desiredKeybindings = @(
	@{ id = "Terminal.OpenNewTab"; keys = "ctrl+t" },
	@{ id = "Terminal.CloseTab"; keys = "ctrl+w" },
	@{ id = "Terminal.SwitchToTab0"; keys = "ctrl+1" },
	@{ id = "Terminal.SwitchToTab1"; keys = "ctrl+2" },
	@{ id = "Terminal.SwitchToTab2"; keys = "ctrl+3" },
	@{ id = "Terminal.SwitchToTab3"; keys = "ctrl+4" },
	@{ id = "Terminal.SwitchToTab4"; keys = "ctrl+5" },
	@{ id = "Terminal.SwitchToTab5"; keys = "ctrl+6" },
	@{ id = "Terminal.SwitchToTab6"; keys = "ctrl+7" },
	@{ id = "Terminal.SwitchToTab7"; keys = "ctrl+8" }
)

$existingKeys = @($desiredKeybindings | ForEach-Object { $_.keys }) + @("ctrl+9")
$keybindings = @($json.keybindings | Where-Object { $_.keys -notin $existingKeys })
$keybindings += $desiredKeybindings | ForEach-Object { [PSCustomObject]$_ }

# Ctrl+9（第 9 個分頁，index 8）沒有對應的內建 id，用 inline command 表示
$keybindings += [PSCustomObject]@{
	keys    = "ctrl+9"
	command = [PSCustomObject]@{ action = "switchToTab"; index = 8 }
}

$json.keybindings = $keybindings

$json | ConvertTo-Json -Depth 30 | Set-Content -Path $settingsPath -Encoding utf8
Write-Host "Windows Terminal 設定已更新：$settingsPath"
