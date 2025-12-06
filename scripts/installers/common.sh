#!/usr/bin/env bash
# Common/shared dependencies installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"

# ============================================================================
# COMMON DEPENDENCIES
# These are used by multiple configs
# ============================================================================

COMMON_DEPS=(
    git
    curl
    wget
)

CORE_DEPS=(
    fd
    fzf
    ripgrep
)

# ============================================================================
# FD INSTALLATION (with alias handling)
# ============================================================================

install_fd() {
    log_step "Installing fd"
    
    if command_exists fd; then
        log_info "fd already installed"
        return 0
    fi
    
    # Check for fdfind (Debian/Ubuntu name)
    if command_exists fdfind; then
        log_info "fdfind found, creating fd alias"
        ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
        log_success "fd alias created"
        return 0
    fi
    
    install_packages fd
    
    # Create alias if fdfind was installed
    if command_exists fdfind && ! command_exists fd; then
        ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
        log_success "fd alias created"
    fi
}

# ============================================================================
# RIPGREP INSTALLATION
# ============================================================================

install_ripgrep() {
    log_step "Installing ripgrep"
    
    if command_exists rg; then
        log_info "ripgrep already installed"
        return 0
    fi
    
    install_packages ripgrep
}

# ============================================================================
# INSTALL ALL COMMON DEPS
# ============================================================================

install_common_deps() {
    log_step "Installing common dependencies"
    
    local missing=()
    
    for dep in "${COMMON_DEPS[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing: ${missing[*]}"
        install_packages "${missing[@]}"
    fi
    
    log_success "Common dependencies installed"
}

install_core_deps() {
    log_step "Installing core dependencies"
    
    # fd
    if ! command_exists fd && ! command_exists fdfind; then
        install_fd
    else
        log_info "fd: installed"
    fi
    
    # fzf - use git version
    if ! command_exists fzf; then
        "$SCRIPT_DIR/fzf.sh" install
    else
        log_info "fzf: installed"
    fi
    
    # ripgrep
    if ! command_exists rg; then
        install_ripgrep
    else
        log_info "ripgrep: installed"
    fi
    
    log_success "Core dependencies installed"
}

# ============================================================================
# CHECKS
# ============================================================================

check_common() {
    echo "=== Common Dependencies ==="
    for dep in "${COMMON_DEPS[@]}"; do
        if command_exists "$dep"; then
            echo "$dep: installed"
        else
            echo "$dep: missing"
        fi
    done
    
    echo ""
    echo "=== Core Dependencies ==="
    
    if command_exists fd; then
        echo "fd: installed"
    elif command_exists fdfind; then
        echo "fd: installed as fdfind"
    else
        echo "fd: missing"
    fi
    
    if command_exists fzf; then
        echo "fzf: installed ($(fzf --version 2>/dev/null | head -1 | awk '{print $1}'))"
    else
        echo "fzf: missing"
    fi
    
    if command_exists rg; then
        echo "ripgrep: installed"
    else
        echo "ripgrep: missing"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    cat <<EOF
Common Dependencies Installer

Usage: $(basename "$0") <command> [options]

Commands:
    common          Install common dependencies (git, curl, wget)
    core            Install core dependencies (fd, fzf, ripgrep)
    fd              Install fd only
    ripgrep         Install ripgrep only
    check           Check installation status
    all             Install all common and core dependencies
    
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
        common)
            install_common_deps
            ;;
        core)
            install_core_deps
            ;;
        fd)
            install_fd
            ;;
        ripgrep|rg)
            install_ripgrep
            ;;
        check)
            check_common
            ;;
        all)
            install_common_deps
            install_core_deps
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
