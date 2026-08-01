#!/bin/bash

source modules/core/common/common.sh
source modules/core/homebrew/homebrew.sh

info "Mac Bootstrap Toolkit"

run_module "Homebrew" check_homebrew

show_summary