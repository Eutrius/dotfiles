#!/usr/bin/env bash
# Tmux installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"

# ============================================================================
# TMUX INSTALLATION
# ============================================================================

install_tmux() {
    log_step "Installing Tmux"
    
    if command_exists tmux; then
        local version
        version="$(tmux -V)"
        log_info "Tmux already installed: $version"
        return 0
    fi
    
    install_packages tmux
    
    if command_exists tmux; then
        log_success "Tmux installed: $(tmux -V)"
    else
        log_error "Failed to install tmux"
        return 1
    fi
}

# ============================================================================
# TMUX DEPENDENCIES
# ============================================================================

TMUX_DEPS=(
    git
)

install_tmux_deps() {
    log_step "Installing Tmux dependencies"
    
    local missing=()
    for dep in "${TMUX_DEPS[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All dependencies already installed"
        return 0
    fi
    
    log_info "Missing dependencies: ${missing[*]}"
    install_packages "${missing[@]}"
}

# ============================================================================
# TMUX PLUGINS
# ============================================================================

setup_tmux_plugins() {
    local dotfiles_dir="${DOTFILES_DIR:-$(get_dotfiles_dir)}"
    
    log_step "Setting up Tmux plugins"
    
    # The resurrect plugin is a submodule, ensure it's initialized
    if [[ -d "$dotfiles_dir/.git" ]]; then
        log_info "Updating tmux plugin submodules..."
        git -C "$dotfiles_dir" submodule update --init --recursive -- tmux/plugins
    fi
    
    log_success "Tmux plugins ready"
}

reload_tmux_config() {
    local dotfiles_dir="${DOTFILES_DIR:-$(get_dotfiles_dir)}"
    
    if [[ -z "${TMUX:-}" ]]; then
        log_info "Not inside tmux session, skipping reload"
        return 0
    fi
    
    log_info "Reloading tmux configuration..."
    tmux source-file "$dotfiles_dir/tmux/tmux.conf" 2>/dev/null || true
    log_success "Tmux config reloaded"
}

# ============================================================================
# CHECKS
# ============================================================================

check_tmux() {
    echo "=== Tmux Status ==="
    
    if command_exists tmux; then
        echo "Tmux: installed ($(tmux -V))"
    else
        echo "Tmux: not installed"
    fi
    
    if [[ -n "${TMUX:-}" ]]; then
        echo "Currently in tmux session: yes"
    else
        echo "Currently in tmux session: no"
    fi
    
    echo ""
    echo "=== Dependencies ==="
    for dep in "${TMUX_DEPS[@]}"; do
        if command_exists "$dep"; then
            echo "$dep: installed"
        else
            echo "$dep: missing"
        fi
    done
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    cat <<EOF
Tmux Installer

Usage: $(basename "$0") <command> [options]

Commands:
    install         Install tmux
    deps            Install tmux dependencies
    plugins         Setup/update tmux plugins
    reload          Reload tmux configuration
    check           Check installation status
    all             Full installation (tmux + deps + plugins)
    
Options:
    --help          Show this help
EOF
}

main() {
    local cmd="${1:-}"
    
    for arg in "$@"; do
        case "$arg" in
            --help|-h) show_help; exit 0;;
        esac
    done
    
    case "$cmd" in
        install)
            install_tmux
            ;;
        deps)
            install_tmux_deps
            ;;
        plugins)
            setup_tmux_plugins
            ;;
        reload)
            reload_tmux_config
            ;;
        check)
            check_tmux
            ;;
        all)
            install_tmux_deps
            install_tmux
            setup_tmux_plugins
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
