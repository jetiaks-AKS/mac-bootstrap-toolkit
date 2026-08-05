#!/bin/bash

# ==========================================
# Git Discovery
# ==========================================

discover_git() {

    if ! command -v git >/dev/null 2>&1; then

        error "Git is not installed"
        return 2

    fi

    local output_dir="config/generated"
    local output_file="$output_dir/git.conf"

    mkdir -p "$output_dir"

    action "Exporting Git configuration..."

    cat > "$output_file" <<EOF
GIT_USER_NAME="$(git config --global user.name)"
GIT_USER_EMAIL="$(git config --global user.email)"
GIT_DEFAULT_BRANCH="$(git config --global init.defaultBranch)"
GIT_PULL_REBASE="$(git config --global pull.rebase)"
GIT_EDITOR="$(git config --global core.editor)"
EOF

    success "Git configuration exported"

    detail "Configuration saved to:"
    detail "$output_file"

    return 0

}
