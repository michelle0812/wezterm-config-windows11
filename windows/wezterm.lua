local wezterm = require("wezterm")
local config = wezterm.config_builder()

local home = os.getenv("USERPROFILE")
local common = dofile(home .. "/.wezterm/common.lua")

-- 字型（原設定用 macOS 的 Monaco，Windows 沒有這個字型，改用 Cascadia Code）
config.font = wezterm.font("Cascadia Code")
config.font_size = 14.0

-- 初始視窗大小：記住上次關閉時的大小
local window_size_cache = wezterm.config_dir .. "/window_size.json"

local function read_last_window_size()
	local file = io.open(window_size_cache, "r")
	if file then
		local content = file:read("*a")
		file:close()
		local ok, data = pcall(wezterm.json_parse, content)
		if ok and data and data.cols and data.rows then
			return data.cols, data.rows
		end
	end
	return 80, 24
end

config.initial_cols, config.initial_rows = read_last_window_size()

wezterm.on("window-resized", function(window, pane)
	local dims = pane:get_dimensions()
	local file = io.open(window_size_cache, "w")
	if file then
		file:write(wezterm.json_encode({ cols = dims.cols, rows = dims.viewport_rows }))
		file:close()
	end
end)

config.window_background_opacity = common.window_background_opacity
config.colors = common.colors

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
