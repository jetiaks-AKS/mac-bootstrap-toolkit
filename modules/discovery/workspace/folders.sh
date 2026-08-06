#!/bin/bash

# ==========================================
# Workspace Folders Discovery
# ==========================================

classify_folder() {

    case "$1" in

        Applications|Library|Public)
            echo "system"
            ;;

        Desktop|Documents|Downloads|Movies|Music|Pictures)
            echo "user"
            ;;

        *)
            echo "workspace"
            ;;

    esac

}

# ==========================================
# Export Workspace Folders
# ==========================================

export_workspace_folders() {

    local output_dir="config/generated/workspace"
    local output_file="$output_dir/folders.conf"

    mkdir -p "$output_dir"

    action "Exporting Workspace Folders..."

    > "$output_file"

    for folder in "$HOME"/*; do

        [[ ! -d "$folder" ]] && continue

        local name
        local type

        name="$(basename "$folder")"
        type="$(classify_folder "$name")"

        echo "$name|$type" >> "$output_file"

    done

    local folder_count
    folder_count=$(wc -l < "$output_file" | tr -d ' ')

    success "$folder_count folder(s) exported"

}
