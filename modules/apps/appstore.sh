#!/bin/bash

# ==========================================
# Install App Store Application
# ==========================================

read_appstore_configuration() {

    local config_file="$1"

    [[ -f "$config_file" && -r "$config_file" ]] || return 2

    LC_ALL=C awk -F "|" '
        /^$/ || /^#/ { next }
        {
            if (NF != 2 || $1 !~ /^[0-9]+$/ || $2 == "" || $2 ~ /^-/ ||
                $2 ~ /^[[:space:]]/ || $2 ~ /[[:space:]]$/ ||
                $2 ~ /[[:cntrl:]]/) exit 2
            print
        }
    ' "$config_file" || return 2

    return 0

}

install_appstore_app() {

    local app_id="$1"
    local app_name="$2"

    action "Installing $app_name..."

    if [[ "$VERBOSE" == true ]]; then

    MAS_NO_AUTO_INDEX=1 mas install "$app_id"

else

    MAS_NO_AUTO_INDEX=1 mas install "$app_id" >/dev/null 2>&1

fi

if [[ $? -eq 0 ]]; then

    success "$app_name installed successfully"
    return 0

fi

error "Failed to install $app_name"
return 2

}

# ==========================================
# Install App Store Applications
# ==========================================

install_appstore_apps() {

    if blueprint_exists &&
       [[ -z "$(blueprint_selected_items app-store)" ]]; then
        success "No App Store applications selected by Blueprint"
        return 0
    fi

    local config_file
    config_file="$(blueprint_generated_file app-store)"

    local applications
    if ! applications="$(read_appstore_configuration "$config_file")"; then

        error "App Store configuration missing, unreadable, or malformed: $config_file"
        return 2

    fi

    if ! command -v mas >/dev/null 2>&1; then
        warning "mas is not installed"
        return 1
    fi

    local installed_apps
    if ! installed_apps="$(MAS_NO_AUTO_INDEX=1 mas list)"; then
        error "Failed to inspect installed App Store applications"
        return 2
    fi

    local missing_apps=0

    while IFS='|' read -r app_id app_name || [[ -n "$app_id" ]]; do

        [[ -z "$app_id" ]] && continue
        [[ "$app_id" =~ ^# ]] && continue
        blueprint_item_selected app-store "$app_id" || continue

        if grep -Fq "$app_name" <<< "$installed_apps"; then

            detail "$app_name is already installed"
            continue

        fi

        ((missing_apps++))

        if [[ $missing_apps -eq 1 ]]; then

            action "Installing App Store Applications..."
            echo

        fi

        install_appstore_app "$app_id" "$app_name"

        if [[ $? -ne 0 ]]; then
            return 2
        fi

        MODULE_CHANGED=true

    done <<< "$applications"

    if [[ $missing_apps -eq 0 ]]; then

        success "All App Store applications are installed."
        return 0

    fi

    echo
    success "App Store applications are ready"

}
