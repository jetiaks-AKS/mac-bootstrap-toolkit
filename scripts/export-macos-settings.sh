#!/bin/bash

EXPORT_DIR="exports/macos"

mkdir -p "$EXPORT_DIR"

echo "=========================================="
echo " Export macOS Settings"
echo "=========================================="

echo "[INFO] Экспорт Finder..."
defaults read com.apple.finder > "$EXPORT_DIR/finder.txt"
echo "[ OK ] Finder"

echo "[INFO] Экспорт Dock..."
defaults read com.apple.dock > "$EXPORT_DIR/dock.txt"
echo "[ OK ] Dock"

echo "[INFO] Экспорт Global..."
defaults read NSGlobalDomain > "$EXPORT_DIR/global.txt"
echo "[ OK ] Global"

echo "[INFO] Экспорт Screenshots..."
defaults read com.apple.screencapture > "$EXPORT_DIR/screenshot.txt"
echo "[ OK ] Screenshots"

echo "[INFO] Экспорт Desktop Services..."
defaults read com.apple.desktopservices > "$EXPORT_DIR/desktopservices.txt"
echo "[ OK ] Desktop Services"

echo "[INFO] Экспорт Login Window..."
defaults read com.apple.loginwindow > "$EXPORT_DIR/loginwindow.txt"
echo "[ OK ] Login Window"

echo
echo "[ OK ] Экспорт macOS завершён"
