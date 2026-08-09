local wezterm = require("wezterm")
local config = wezterm.config_builder()

local home = os.getenv("HOME")
local common = dofile(home .. "/.wezterm/common.lua")

-- 字型
config.font = wezterm.font("Monaco")
config.font_size = 20.0

-- 初始視窗大小
config.initial_cols = 80
config.initial_rows = 24

config.window_background_opacity = common.window_background_opacity
config.colors = common.colors

-- 標題列背景色跟隨終端機背景色（需要 wezterm@nightly，穩定版 cask 版本太舊沒有這個功能）
config.window_decorations = "TITLE | RESIZE | MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR"

-- 快捷鍵：Ctrl+T 開新分頁，Ctrl+1~9 切換到對應分頁，Ctrl+W 關閉目前分頁
config.keys = {
	{ key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "1", mods = "CTRL", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "CTRL", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "CTRL", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "CTRL", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "CTRL", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "CTRL", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "CTRL", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "CTRL", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "CTRL", action = wezterm.action.ActivateTab(8) },
}

return config
