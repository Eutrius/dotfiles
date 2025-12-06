#!/usr/bin/env bash
# Zsh installer and configurator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"

# ============================================================================
# ZSH INSTALLATION
# ============================================================================

install_zsh() {
    log_step "Installing Zsh"
    
    if command_exists zsh; then
        local version
        version="$(zsh --version | head -1)"
        log_info "Zsh already installed: $version"
        return 0
    fi
    
    install_packages zsh
    
    if command_exists zsh; then
        log_success "Zsh installed: $(zsh --version | head -1)"
    else
        log_error "Failed to install zsh"
        return 1
    fi
}

set_default_shell() {
    log_step "Setting Zsh as default shell"
    
    local current_shell
    current_shell="$(basename "$SHELL")"
    
    if [[ "$current_shell" == "zsh" ]]; then
        log_info "Zsh is already the default shell"
        return 0
    fi
    
    if ! command_exists zsh; then
        log_error "Zsh is not installed"
        return 1
    fi
    
    local zsh_path
    zsh_path="$(command -v zsh)"
    
    # Check if zsh is in /etc/shells
    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        log_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | run_privileged tee -a /etc/shells >/dev/null
    fi
    
    log_info "Changing default shell to $zsh_path"
    
    if chsh -s "$zsh_path"; then
        log_success "Default shell changed to zsh"
        log_warn "Please log out and back in for changes to take effect"
    else
        log_warn "chsh failed, trying with sudo..."
        if run_privileged chsh -s "$zsh_path" "$USER"; then
            log_success "Default shell changed to zsh"
            log_warn "Please log out and back in for changes to take effect"
        else
            log_error "Failed to change default shell"
            log_info "Try manually: chsh -s $zsh_path"
            return 1
        fi
    fi
}

# ============================================================================
# ZSH DEPENDENCIES
# ============================================================================

ZSH_DEPS=(
    git
    curl
    fzf
    eza
)

install_zsh_deps() {
    log_step "Installing Zsh dependencies"
    
    local missing=()
    for dep in "${ZSH_DEPS[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All required dependencies installed"
    else
        log_info "Missing dependencies: ${missing[*]}"
        
        if is_interactive; then
            mapfile -t to_install < <(select_items "Select dependencies to install:" "${missing[@]}")
        else
            to_install=("${missing[@]}")
        fi
        
        for dep in "${to_install[@]}"; do
            case "$dep" in
                fzf)
                    # Use our fzf installer
                    "$SCRIPT_DIR/fzf.sh" install
                    ;;
                eza)
                    install_eza
                    ;;
                *)
                    install_packages "$dep"
                    ;;
            esac
        done
    fi
}

# ============================================================================
# EZA INSTALLATION
# ============================================================================

install_eza() {
    log_step "Installing eza"
    
    if command_exists eza; then
        log_info "eza already installed: $(eza --version | head -1)"
        return 0
    fi
    
    # Always install from GitHub releases for latest version
    log_info "Installing eza from GitHub releases..."
    
    local version
    version="$(get_latest_github_release "eza-community/eza")"
    [[ -z "$version" ]] && version="v0.20.10"
    
    local archive
    
    case "$OS-$ARCH" in
        linux-x86_64)
            archive="eza_x86_64-unknown-linux-gnu.tar.gz"
            ;;
        linux-arm64)
            archive="eza_aarch64-unknown-linux-gnu.tar.gz"
            ;;
        linux-armv7)
            archive="eza_arm-unknown-linux-gnueabihf.tar.gz"
            ;;
        macos-x86_64)
            archive="eza_x86_64-apple-darwin.tar.gz"
            ;;
        macos-arm64)
            archive="eza_aarch64-apple-darwin.tar.gz"
            ;;
        *)
            log_error "Unsupported platform: $OS-$ARCH"
            return 1
            ;;
    esac
    
    local url="https://github.com/eza-community/eza/releases/download/${version}/${archive}"
    local tmp
    tmp="$(mktemp -d)"
    
    download_file "$url" "$tmp/$archive"
    tar -C "$tmp" -xzf "$tmp/$archive"
    install -m755 "$tmp/eza" "$LOCAL_BIN/eza"
    rm -rf "$tmp"
    
    log_success "eza installed"
}

# ============================================================================
# ZSH CONFIGURATION
# ============================================================================

setup_zshrc() {
    local dotfiles_dir="${DOTFILES_DIR:-$(get_dotfiles_dir)}"
    local zshrc="$HOME/.zshrc"
    local source_line="source $dotfiles_dir/zsh/init.zsh"
    
    log_step "Configuring .zshrc"
    
    # Create .zshrc if it doesn't exist
    touch "$zshrc"
    
    # Check if source line already exists
    if grep -Fxq "$source_line" "$zshrc" 2>/dev/null; then
        log_info "Source line already in .zshrc"
        return 0
    fi
    
    # Add source line
    echo "$source_line" >> "$zshrc"
    log_success "Added source line to .zshrc"
}

remove_zshrc_config() {
    local dotfiles_dir="${DOTFILES_DIR:-$(get_dotfiles_dir)}"
    local zshrc="$HOME/.zshrc"
    local source_line="source $dotfiles_dir/zsh/init.zsh"
    
    if [[ ! -f "$zshrc" ]]; then
        return 0
    fi
    
    log_info "Removing dotfiles source line from .zshrc"
    grep -Fxv "$source_line" "$zshrc" > "$zshrc.tmp" || true
    mv "$zshrc.tmp" "$zshrc"
}

# ============================================================================
# CHECKS
# ============================================================================

check_zsh() {
    echo "=== Zsh Status ==="
    
    if command_exists zsh; then
        echo "Zsh: installed ($(zsh --version | head -1))"
    else
        echo "Zsh: not installed"
    fi
    
    echo "Default shell: $SHELL"
    
    echo ""
    echo "=== Dependencies ==="
    for dep in "${ZSH_DEPS[@]}" "${ZSH_OPTIONAL_DEPS[@]}"; do
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
Zsh Installer

Usage: $(basename "$0") <command> [options]

Commands:
    install         Install zsh
    set-default     Set zsh as default shell
    deps            Install zsh dependencies (fzf, eza, etc.)
    eza             Install eza only
    starship        Install starship prompt
    setup           Add source line to .zshrc
    check           Check installation status
    all             Full installation (zsh + deps + set-default + setup)
    
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
            install_zsh
            ;;
        set-default)
            set_default_shell
            ;;
        deps)
            install_zsh_deps
            ;;
        eza)
            install_eza
            ;;
        starship)
            install_starship
            ;;
        setup)
            setup_zshrc
            ;;
        remove-config)
            remove_zshrc_config
            ;;
        check)
            check_zsh
            ;;
        all)
            install_zsh
            install_zsh_deps
            setup_zshrc
            if is_interactive && ask_yes_no "Set zsh as default shell?" "y"; then
                set_default_shell
            fi
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
