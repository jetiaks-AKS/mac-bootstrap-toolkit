#!/bin/bash

# ==========================================
# Repository Helpers
# ==========================================

# ==========================================
# Repository Exists
# ==========================================

repository_exists() {

    local repository_path="$1"

    [[ -d "$repository_path" ]]

}

# ==========================================
# Repository Is Git
# ==========================================

repository_is_git() {

    local repository_path="$1"

    [[ -d "$repository_path/.git" ]]

}

# ==========================================
# Repository Origin
# ==========================================

repository_origin() {

    local repository_path="$1"

    git -C "$repository_path" remote get-url origin 2>/dev/null

}

# ==========================================
# Repository Branch
# ==========================================

repository_branch() {

    local repository_path="$1"

    git -C "$repository_path" branch --show-current 2>/dev/null

}

# ==========================================
# Clone Repository
# ==========================================

repository_clone() {

    local remote="$1"
    local path="$2"

    git clone "$remote" "$path"

}

# ==========================================
# Repository Is Clean
# ==========================================

repository_is_clean() {

    local repository_path="$1"

    git -C "$repository_path" diff --quiet &&
    git -C "$repository_path" diff --cached --quiet

}

# ==========================================
# Repository Checkout
# ==========================================

repository_checkout() {

    local repository_path="$1"
    local branch="$2"

    git -C "$repository_path" checkout "$branch" >/dev/null 2>&1

}

# ==========================================
# Verify Repository
# ==========================================

repository_verify() {

    local path="$1"
    local expected_remote="$2"
    local expected_branch="$3"

    local repository_cloned=false

    if ! repository_exists "$path"; then

        action "Cloning repository..."

        if ! repository_clone "$expected_remote" "$path"; then
            error "Failed to clone repository"
            return 1
        fi

        success "Repository cloned"

        MODULE_CHANGED=true
        repository_cloned=true

    fi

    if [[ "$repository_cloned" == false ]]; then
        success "Repository found"
    fi

    if ! repository_is_git "$path"; then
        warning "Directory is not a Git repository"
        return 1
    fi

    success "Git repository detected"

    local current_remote

    current_remote=$(repository_origin "$path")

    if [[ "$current_remote" != "$expected_remote" ]]; then
        warning "Remote does not match"
        return 1
    fi

    success "Remote verified"

    local current_branch

    current_branch=$(repository_branch "$path")

if [[ "$current_branch" != "$expected_branch" ]]; then

    warning "Branch does not match"

    if ! repository_is_clean "$path"; then
        warning "Repository has uncommitted changes"
        return 1
    fi

    action "Restoring branch..."

    if ! repository_checkout "$path" "$expected_branch"; then
        error "Failed to restore branch"
        return 1
    fi

    MODULE_CHANGED=true

    success "Branch restored"

    current_branch=$(repository_branch "$path")

    if [[ "$current_branch" != "$expected_branch" ]]; then
        error "Branch verification failed"
        return 1
    fi

fi

success "Branch verified"

return 0

}
