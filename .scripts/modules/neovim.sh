#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"

NEOVIM_VERSION="${NEOVIM_VERSION:-}"

neovim_install() {
    local version="$1"
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    local install_share="${SHARE_PATH:-$LOCAL_SHARE}"
    local nvim_dir="$install_share/nvim-install"
    local nvim_extracted
    
    nvim_extracted="$(find . -maxdepth 1 -type d -name 'nvim-*' | head -1)"
    if [[ -n "$nvim_extracted" ]]; then
        run_privileged rm -rf "$nvim_dir"
        run_privileged mkdir -p "$install_share"
        run_privileged mv "$nvim_extracted" "$nvim_dir"
        run_privileged ln -sf "$nvim_dir/bin/nvim" "$install_bin/nvim"
        return 0
    fi
    return 1
}

neovim_remove() {
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    local install_share="${SHARE_PATH:-$LOCAL_SHARE}"
    
    # Remove from /usr/local if exists there
    if [[ -e "/usr/local/bin/nvim" ]] || [[ -L "/usr/local/bin/nvim" ]]; then
        run_privileged rm -f "/usr/local/bin/nvim"
        run_privileged rm -rf "/usr/local/share/nvim-install"
    fi
    
    # Also try local paths
    if [[ -e "$install_bin/nvim" ]] || [[ -L "$install_bin/nvim" ]]; then
        if [[ "$install_bin" == "/usr/local/bin" ]]; then
            run_privileged rm -f "$install_bin/nvim"
        else
            rm -f "$install_bin/nvim"
        fi
    fi
    
    if [[ -e "$install_share/nvim-install" ]]; then
        if [[ "$install_share" == "/usr/local/share" ]]; then
            run_privileged rm -rf "$install_share/nvim-install"
        else
            rm -rf "$install_share/nvim-install"
        fi
    fi
}

neovim_version() {
    nvim --version 2>/dev/null | head -1
}
