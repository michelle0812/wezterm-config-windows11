# wezterm-config-windows11

UncleSam 的 Windows 11 終端機環境設定備份（WezTerm + Windows Terminal / PowerShell + Tabby）。

## 一鍵安裝

在全新的 Windows 11 機器上，開一個 PowerShell 視窗，貼上這行執行即可（會跳出一次 UAC 視窗要求系統管理員權限，用來建立 symlink）：

```powershell
irm https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1 | iex
```

這會自動依序完成：確認/安裝 Node.js、Claude Code、git、GitHub CLI（已安裝的會略過）→ clone 這個 repo 到 `~/.wezterm` → 安裝 WezTerm / Tabby → 套用 WezTerm / Windows Terminal / Tabby 設定。完成後重新開啟 WezTerm、Windows Terminal 或 Tabby 就可以看到效果。

下面是每個步驟的詳細說明（`bootstrap.ps1` 背後其實就是照這個順序做），也是寫給 AI agent（例如 Claude Code）在需要手動介入或除錯時參考用的。

## 給 AI 的安裝順序

以下步驟請照順序執行。**步驟 1 和步驟 2 需要人類在場**完成瀏覽器授權，不能單靠腳本自動完成；其餘步驟都能自動化。

### 步驟 1：確認 / 安裝 Node.js、Claude Code、git 與 GitHub CLI

Node.js、Claude Code 是為了讓 AI agent 本身能在這台機器上跑起來；git、GitHub CLI 則是因為這是 private repo，必須先有這兩個工具才能 clone。每一項都先判斷是否已安裝，沒有才安裝，避免重複安裝。

```powershell
# Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    winget install --id OpenJS.NodeJS.LTS -e --source winget --accept-package-agreements --accept-source-agreements
}

# Claude Code（需要先有 Node.js/npm；如果上一步剛裝完 Node.js，請先開新終端機視窗再執行這段，讓 PATH 生效）
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    npm install -g @anthropic-ai/claude-code
}

# git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
}

# GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements
}
```

裝完後**開一個新的終端機視窗**（舊視窗的 PATH 不會自動更新），確認：

```powershell
node --version
claude --version
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

會自動安裝 WezTerm / Tabby、套用 WezTerm 設定（symlink `~/.wezterm.lua`）、套用 Windows Terminal / PowerShell 的透明度與快捷鍵設定、套用 Tabby 的配色/透明度/模糊/快捷鍵設定，並修正開始選單「Windows PowerShell」捷徑以系統管理員身分執行時會跑到 `C:\Windows\System32` 的問題。

```powershell
cd "$env:USERPROFILE\.wezterm"
.\install.ps1
```

### 步驟 5：驗證

先確認指令行抓得到 WezTerm（跟步驟 1 驗證 node/claude/git/gh 是同樣道理，只是 WezTerm 是這一步才裝的）：

```powershell
wezterm --version
```

Tabby 沒有指令列工具可以驗證版本，改用「設定」-「應用程式」確認清單裡有 Tabby，或直接從開始選單開開看。

再實際打開來看效果：

- 開 WezTerm：背景應該是透明的（`window_background_opacity = 0.9`），`Ctrl+T`/`Ctrl+W`/`Ctrl+1~9` 應該能開新分頁/關閉分頁/切換分頁
- 開 Windows Terminal 的 PowerShell profile：背景也應該是透明的，一樣有 `Ctrl+T`/`Ctrl+W`/`Ctrl+1~9`
- 開 Tabby：配色是 1984 Dark、背景透明度 0.9 且開啟模糊，`Ctrl+T`/`Ctrl+W`/`Ctrl+1~9` 一樣能開新分頁/關閉分頁/切換分頁
- 從開始選單搜尋 PowerShell，右鍵選「以系統管理員身分執行」：應該直接進入使用者資料夾（`C:\Users\<你的帳號>`），而不是 `C:\Windows\System32`

## 反安裝 / 重新安裝

如果裝壞了，或想清乾淨重新測試一鍵安裝流程，用 `uninstall.ps1`：

```powershell
cd "$env:USERPROFILE\.wezterm"

# 只還原 WezTerm / Windows Terminal / Tabby 設定、刪掉 ~/.wezterm 與 symlink
# 保留 Node.js / Claude Code / git / GitHub CLI / WezTerm / Tabby 本身
.\uninstall.ps1

# 連同 bootstrap.ps1 裝的 Node.js / Claude Code / git / GitHub CLI / WezTerm / Tabby
# 一起解除安裝，還原到接近全新機器的狀態
.\uninstall.ps1 -Full
```

清完之後，直接重跑一鍵安裝那行指令（見最上方）即可從頭再測一次。

**注意**：`-Full` 會移除 git / gh / Node.js 這類通用開發工具，如果這台機器上還有其他專案依賴它們，不要用 `-Full`；另外 winget 解除安裝不保證清掉所有使用者層級的殘留設定/快取，要 100% 乾淨最保險的方式還是用全新的 VM 或映像檔測試。

## 已知限制

- **symlink 權限**：`bin/setup.ps1` 會用 `New-Item -ItemType SymbolicLink` 建立 `~/.wezterm.lua`，這在 Windows 上預設需要系統管理員權限，除非該台電腦已經開啟「設定 → 隱私權與安全性 → 開發人員模式」。如果遇到權限錯誤，開發人員模式或用系統管理員身分重跑 `install.ps1` 即可。
- **字型**：`windows/wezterm.lua` 用的是 `Cascadia Code`（Windows Terminal 內建字型），如果新機器沒有 Windows Terminal，可能要額外安裝字型。
- **Windows Terminal 關閉分頁沒有確認提示**：`Ctrl+W` 會直接關閉分頁，Windows Terminal 目前沒有提供像 WezTerm `confirm = true` 那種單一分頁關閉前跳提示的功能。
- **Tabby 的模糊只有開關，沒有強度**：Windows 上是透過 `DwmEnableBlurBehindWindow` 實作，只能開/關，無法像有些應用一樣調整模糊程度；`bin/setup-tabby.ps1` 固定套用 `opacity: 0.9` + `vibrancy: true`。
- **`bin/setup-tabby.ps1` 需要 `powershell-yaml` 模組**：因為 Tabby 設定檔是 YAML 而不是 JSON（Windows PowerShell 5.1 沒有內建的 `ConvertFrom-Yaml`），腳本第一次執行時會自動從 PSGallery 安裝這個模組。

## 檔案結構

```
.wezterm/
├── bootstrap.ps1                  -- 全自動一鍵安裝腳本（裝好 Node.js/Claude Code/git/gh，clone 好之後自動接著跑 install.ps1）
├── install.ps1                    -- WezTerm/設定安裝腳本（步驟 4 用這個，也會被 bootstrap.ps1 自動呼叫）
├── uninstall.ps1                  -- 反安裝腳本（清掉設定，加 -Full 連同裝的工具一起移除）
├── loader.lua                     -- 依平台載入對應設定，會被 symlink 成 ~/.wezterm.lua
├── common.lua                     -- 跨平台共用設定（1984 Dark 配色 + 透明度）
├── windows/wezterm.lua            -- Windows 版 WezTerm 設定
├── macos/wezterm.lua              -- macOS 版 WezTerm 設定（實際使用中的版本在 michelle0812/dotfiles）
├── windows-terminal/settings.json -- Windows Terminal 設定備份（參考用，實際套用邏輯在 bin/setup-windows-terminal.ps1）
└── bin/
    ├── setup.ps1                  -- symlink ~/.wezterm.lua -> loader.lua
    ├── setup.sh                   -- macOS 版 symlink 腳本
    ├── setup-windows-terminal.ps1 -- 合併 Windows Terminal 的透明度/快捷鍵設定，並修正開始選單 PowerShell 捷徑的起始位置
    └── setup-tabby.ps1            -- 合併 Tabby 的 1984 Dark 配色/透明度/模糊/快捷鍵設定
```
