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
# Verify Repository
# ==========================================

repository_verify() {

    local path="$1"
    local expected_remote="$2"
    local expected_branch="$3"

  if ! repository_exists "$path"; then

    action "Cloning repository..."

    repository_clone "$expected_remote" "$path"

    if ! repository_clone "$expected_remote" "$path"; then
    error "Failed to clone repository"
    return 1
    fi

    success "Repository cloned"

  fi

    success "Repository found"

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
        return 1
    fi

    success "Branch verified"

    return 0

}

# ==========================================
# Clone Repository
# ==========================================

repository_clone() {

    local remote="$1"
    local path="$2"

    git clone "$remote" "$path"

}
