#!/bin/bash

# ==========================================
# Discovery Controller
# ==========================================

run_discovery() {

    run_module "Homebrew Discovery" discover_homebrew

    run_module "Git Discovery" discover_git

}
