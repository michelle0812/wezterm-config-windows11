# 把 1984 Dark 配色 + 透明度/模糊 + Ctrl+T / Ctrl+W / Ctrl+1~9 快捷鍵合併進 Tabby 的設定
# 只會修改需要的欄位，不會整份覆蓋，執行多次結果一樣（idempotent）
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
	Write-Host "==> 安裝 powershell-yaml 模組（用來讀寫 Tabby 的 YAML 設定檔）..."
	if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
	}
	if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
		Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
	}
	Install-Module -Name powershell-yaml -Scope CurrentUser -Force -AllowClobber
}
Import-Module powershell-yaml

$configPath = "$env:APPDATA\tabby\config.yaml"
$configDir = Split-Path $configPath -Parent

if (-not (Test-Path $configDir)) {
	New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if (Test-Path $configPath) {
	$backup = "$configPath.bak.$(Get-Date -Format yyyyMMddHHmmss)"
	Copy-Item $configPath $backup
	Write-Host "已備份原始設定到 $backup"
	$raw = Get-Content $configPath -Raw
	$config = if ($raw.Trim()) { ConvertFrom-Yaml $raw } else { @{} }
} else {
	Write-Host "==> 找不到既有的 Tabby 設定，建立新的設定檔"
	$config = @{}
}
if ($null -eq $config) { $config = @{} }

if (-not $config.ContainsKey("version")) { $config["version"] = 8 }

# 1) 1984 Dark 配色，比照 common.lua
if (-not $config.ContainsKey("terminal")) { $config["terminal"] = @{} }
$config["terminal"]["colorScheme"] = @{
	name       = "1984 Dark"
	foreground = "#ffffff"
	background = "#0d0f31"
	cursor     = "#59e1e3"
	colors     = @(
		"#000000", "#ff16b0", "#b3f361", "#ffea16", "#46bdff", "#f806fa", "#59e1e3", "#feffff",
		"#000000", "#ff16b0", "#b3f361", "#ffea16", "#46bdff", "#f806fa", "#6be4e6", "#feffff"
	)
}

# 2) 透明度 + 模糊，比照 WezTerm 的 window_background_opacity = 0.9
#    Tabby 在 Windows 上的模糊（DwmEnableBlurBehindWindow）只有開關兩種狀態，沒有強度可調
if (-not $config.ContainsKey("appearance")) { $config["appearance"] = @{} }
$config["appearance"]["opacity"] = 0.9
$config["appearance"]["vibrancy"] = $true

# 3) 快捷鍵：Ctrl+T 開新分頁、Ctrl+W 關閉分頁、Ctrl+1~9 切換分頁
if (-not $config.ContainsKey("hotkeys")) { $config["hotkeys"] = @{} }
$config["hotkeys"]["new-tab"] = @("Ctrl-T")
$config["hotkeys"]["close-tab"] = @("Ctrl-W")
for ($i = 1; $i -le 9; $i++) {
	$config["hotkeys"]["tab-$i"] = @("Ctrl-$i")
}

ConvertTo-Yaml $config | Set-Content -Path $configPath -Encoding utf8
Write-Host "Tabby 設定已更新：$configPath"
Write-Host "若 Tabby 目前正在執行中，請完全結束程式（不是縮小到系統匣）後重開，設定才不會被覆蓋回去"
