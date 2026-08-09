# wezterm-config-windows11

UncleSam 的 Windows 11 終端機環境設定備份（WezTerm + Windows Terminal / PowerShell）。
這份說明是寫給 AI agent（例如 Claude Code）在一台全新的 Windows 11 機器上讀取後，依序執行安裝用的。

## 給 AI 的安裝順序

以下步驟請照順序執行。**步驟 1 和步驟 2 需要人類在場**完成瀏覽器授權，不能單靠腳本自動完成；其餘步驟都能自動化。

### 步驟 1：安裝 git 與 GitHub CLI（因為這是 private repo，必須先有這兩個工具才能 clone）

```powershell
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements
```

裝完後**開一個新的終端機視窗**（舊視窗的 PATH 不會自動更新），確認：

```powershell
git --version
gh --version
```

### 步驟 2：登入 GitHub（需要人類手動完成瀏覽器授權）

```powershell
gh auth login
```

依畫面指示選擇 `GitHub.com` → `HTTPS` → `Login with a web browser`，貼一次性驗證碼、在瀏覽器完成授權。
登入完成後執行，讓 git 也能用這組憑證：

```powershell
gh auth setup-git
```

### 步驟 3：Clone 這個 repo 到 `~/.wezterm`

資料夾名稱必須是 `.wezterm`，因為 `loader.lua` 裡的路徑是寫死的。

```powershell
git clone https://github.com/michelle0812/wezterm-config-windows11.git "$env:USERPROFILE\.wezterm"
```

### 步驟 4：執行安裝腳本

會自動安裝 WezTerm、套用 WezTerm 設定（symlink `~/.wezterm.lua`）、套用 Windows Terminal / PowerShell 的透明度與快捷鍵設定。

```powershell
cd "$env:USERPROFILE\.wezterm"
.\install.ps1
```

### 步驟 5：驗證

- 開 WezTerm：背景應該是透明的（`window_background_opacity = 0.9`），`Ctrl+T`/`Ctrl+W`/`Ctrl+1~9` 應該能開新分頁/關閉分頁/切換分頁
- 開 Windows Terminal 的 PowerShell profile：背景也應該是透明的，一樣有 `Ctrl+T`/`Ctrl+W`/`Ctrl+1~9`

## 已知限制

- **symlink 權限**：`bin/setup.ps1` 會用 `New-Item -ItemType SymbolicLink` 建立 `~/.wezterm.lua`，這在 Windows 上預設需要系統管理員權限，除非該台電腦已經開啟「設定 → 隱私權與安全性 → 開發人員模式」。如果遇到權限錯誤，開發人員模式或用系統管理員身分重跑 `install.ps1` 即可。
- **字型**：`windows/wezterm.lua` 用的是 `Cascadia Code`（Windows Terminal 內建字型），如果新機器沒有 Windows Terminal，可能要額外安裝字型。
- **Windows Terminal 關閉分頁沒有確認提示**：`Ctrl+W` 會直接關閉分頁，Windows Terminal 目前沒有提供像 WezTerm `confirm = true` 那種單一分頁關閉前跳提示的功能。

## 檔案結構

```
.wezterm/
├── install.ps1                    -- 一鍵安裝腳本（步驟 4 用這個）
├── loader.lua                     -- 依平台載入對應設定，會被 symlink 成 ~/.wezterm.lua
├── common.lua                     -- 跨平台共用設定（1984 Dark 配色 + 透明度）
├── windows/wezterm.lua            -- Windows 版 WezTerm 設定
├── macos/wezterm.lua              -- macOS 版 WezTerm 設定（實際使用中的版本在 michelle0812/dotfiles）
├── windows-terminal/settings.json -- Windows Terminal 設定備份（參考用，實際套用邏輯在 bin/setup-windows-terminal.ps1）
└── bin/
    ├── setup.ps1                  -- symlink ~/.wezterm.lua -> loader.lua
    ├── setup.sh                   -- macOS 版 symlink 腳本
    └── setup-windows-terminal.ps1 -- 合併 Windows Terminal 的透明度/快捷鍵設定
```
