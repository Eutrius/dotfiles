#!/usr/bin/env bash
# fzf installer
# Uses junegunn/fzf.git for better integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Configuration
FZF_DIR="${FZF_DIR:-$HOME/.fzf}"
FZF_REPO="https://github.com/junegunn/fzf.git"

# ============================================================================
# FZF INSTALLATION
# ============================================================================

get_installed_fzf_version() {
    if command_exists fzf; then
        fzf --version 2>/dev/null | head -1 | awk '{print $1}' || echo "unknown"
    else
        echo "not installed"
    fi
}

install_fzf() {
    local force="${1:-false}"
    
    log_step "Installing fzf (junegunn/fzf)"
    
    # Clone or update
    if [[ -d "$FZF_DIR" ]]; then
        if [[ "$force" == "true" ]]; then
            log_info "Updating fzf..."
            git -C "$FZF_DIR" pull --ff-only
        else
            log_info "fzf directory exists at $FZF_DIR"
            if is_interactive && ! ask_yes_no "Update fzf?" "y"; then
                return 0
            fi
            git -C "$FZF_DIR" pull --ff-only
        fi
    else
        log_info "Cloning fzf..."
        git clone --depth 1 "$FZF_REPO" "$FZF_DIR"
    fi
    
    # Run install script
    log_info "Running fzf install script..."
    
    local install_opts=()
    
    # Determine which shell integrations to install
    if is_interactive; then
        ask_yes_no "Add fzf key bindings?" "y" && install_opts+=(--key-bindings) || install_opts+=(--no-key-bindings)
        ask_yes_no "Add fzf completion?" "y" && install_opts+=(--completion) || install_opts+=(--no-completion)
        ask_yes_no "Update shell config files?" "n" && install_opts+=(--update-rc) || install_opts+=(--no-update-rc)
    else
        install_opts+=(--key-bindings --completion --no-update-rc)
    fi
    
    "$FZF_DIR/install" "${install_opts[@]}"
    
    # Create symlink to local bin
    ensure_dir "$LOCAL_BIN"
    ln -sf "$FZF_DIR/bin/fzf" "$LOCAL_BIN/fzf"
    [[ -f "$FZF_DIR/bin/fzf-tmux" ]] && ln -sf "$FZF_DIR/bin/fzf-tmux" "$LOCAL_BIN/fzf-tmux"
    
    log_success "fzf installed: $(get_installed_fzf_version)"
}

uninstall_fzf() {
    log_step "Uninstalling fzf"
    
    if [[ -d "$FZF_DIR" ]]; then
        # Run uninstall script if it exists
        if [[ -f "$FZF_DIR/uninstall" ]]; then
            "$FZF_DIR/uninstall"
        fi
        
        rm -rf "$FZF_DIR"
        log_success "Removed $FZF_DIR"
    fi
    
    # Remove symlinks
    [[ -L "$LOCAL_BIN/fzf" ]] && rm "$LOCAL_BIN/fzf"
    [[ -L "$LOCAL_BIN/fzf-tmux" ]] && rm "$LOCAL_BIN/fzf-tmux"
    
    log_success "fzf uninstalled"
}

check_fzf() {
    local status="not installed"
    
    if command_exists fzf; then
        status="installed: $(get_installed_fzf_version)"
        
        if [[ -d "$FZF_DIR" ]]; then
            status="$status (from git: $FZF_DIR)"
        fi
    fi
    
    echo "$status"
    command_exists fzf
}

update_fzf() {
    log_step "Updating fzf"
    
    if [[ ! -d "$FZF_DIR" ]]; then
        log_warn "fzf not installed via git, cannot update"
        return 1
    fi
    
    local old_version new_version
    old_version="$(get_installed_fzf_version)"
    
    git -C "$FZF_DIR" pull --ff-only
    "$FZF_DIR/install" --bin
    
    new_version="$(get_installed_fzf_version)"
    
    if [[ "$old_version" != "$new_version" ]]; then
        log_success "fzf updated: $old_version -> $new_version"
    else
        log_info "fzf already up to date: $new_version"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    cat <<EOF
fzf Installer (via junegunn/fzf.git)

Usage: $(basename "$0") <command> [options]

Commands:
    install         Install fzf from git
    uninstall       Remove fzf installation
    update          Update fzf to latest version
    check           Check installation status
    
Options:
    --force         Force reinstall
    --help          Show this help

Environment:
    FZF_DIR         Installation directory (default: ~/.fzf)
EOF
}

main() {
    local cmd="${1:-}"
    local force="false"
    
    for arg in "$@"; do
        case "$arg" in
            --force) force="true";;
            --help|-h) show_help; exit 0;;
        esac
    done
    
    case "$cmd" in
        install)
            install_fzf "$force"
            ;;
        uninstall)
            uninstall_fzf
            ;;
        update)
            update_fzf
            ;;
        check)
            check_fzf
            ;;
        "")
            show_help
            exit 1
            ;;
        *)
            log_error "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
