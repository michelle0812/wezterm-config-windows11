#!/usr/bin/env bash
# macOS 安裝腳本：把 ~/.wezterm.lua symlink 到這個 repo 的 loader.lua
set -e
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HOME/.wezterm.lua"
SOURCE="$REPO_DIR/loader.lua"

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
	BACKUP="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
	mv "$TARGET" "$BACKUP"
	echo "既有設定已備份到 $BACKUP"
fi

ln -sf "$SOURCE" "$TARGET"
echo "已建立 symlink: $TARGET -> $SOURCE"
