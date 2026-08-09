@echo off
echo ============================================
echo   wezterm-config-windows11 - One-Click Setup
echo ============================================
echo.
echo This will install Node.js / Claude Code / git / GitHub CLI / WezTerm
echo and apply WezTerm + Windows Terminal settings.
echo A UAC prompt will appear once - please click "Yes".
echo.
pause

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/michelle0812/wezterm-config-windows11/main/bootstrap.ps1 | iex"

echo.
echo Setup finished.
pause
