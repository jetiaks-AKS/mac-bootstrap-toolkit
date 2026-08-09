#!/bin/bash

# ==========================================
# Discovery Controller
# ==========================================

run_discovery() {

    run_module "Homebrew Discovery" discover_homebrew

    run_module "App Store Discovery" discover_appstore

    run_module "Git Discovery" discover_git

    run_module "VS Code Discovery" discover_vscode

    run_module "macOS Discovery" discover_macos

    run_module "Workspace Discovery" discover_workspace

}
