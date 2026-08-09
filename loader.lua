-- 這個檔案會被 symlink 成 ~/.wezterm.lua，依平台載入對應設定
local wezterm = require("wezterm")
local home = os.getenv("USERPROFILE") or os.getenv("HOME")

local platform_file
if wezterm.target_triple:find("windows") then
	platform_file = home .. "/.wezterm/windows/wezterm.lua"
else
	platform_file = home .. "/.wezterm/macos/wezterm.lua"
end

return dofile(platform_file)
