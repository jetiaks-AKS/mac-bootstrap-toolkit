#!/bin/bash

EXPORT_DIR="exports/macos"

echo "=========================================="
echo " macOS Settings Analyzer"
echo "=========================================="
echo

# ==========================================
# Finder
# ==========================================

analyze_finder() {

    local file="$EXPORT_DIR/finder.txt"

    if [[ ! -f "$file" ]]; then

        echo "[WARN] Finder не экспортирован"
        echo
        return

    fi

    echo "=========================================="
    echo " Finder"
    echo "=========================================="

    if grep -q "AppleShowAllExtensions = 1;" "$file"; then
        echo "✅ Показывать расширения файлов"
    else
        echo "❌ Показывать расширения файлов"
    fi

    if grep -q "ShowPathbar = 1;" "$file"; then
        echo "✅ Показывать путь"
    else
        echo "❌ Показывать путь"
    fi

    if grep -q "ShowStatusBar = 1;" "$file"; then
        echo "✅ Показывать строку состояния"
    else
        echo "❌ Показывать строку состояния"
    fi

    if grep -q 'FXPreferredViewStyle = "Nlsv";' "$file"; then
        echo "✅ Вид списка по умолчанию"
    else
        echo "❌ Вид списка по умолчанию"
    fi

    if grep -q 'FXDefaultSearchScope = "SCcf";' "$file"; then
        echo "✅ Поиск в текущей папке"
    else
        echo "❌ Поиск в текущей папке"
    fi

    echo

}

analyze_finder
