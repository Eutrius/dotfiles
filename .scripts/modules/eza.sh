#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"

eza_version() {
    eza --version 2>/dev/null | sed -n '2p'
}

eza_remove() {
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    
    if [[ -f "/usr/local/bin/eza" ]]; then
        run_privileged rm -f "/usr/local/bin/eza"
    else
        rm -f "$install_bin/eza"
    fi
}
