#!/bin/bash

source modules/core/common/common.sh
source modules/core/homebrew/homebrew.sh
source modules/core/git/git.sh
source modules/core/ssh/ssh.sh

info "Mac Bootstrap Toolkit"

run_module "Homebrew" check_homebrew
run_module "Git" check_git
run_module "SSH" check_ssh

show_summary