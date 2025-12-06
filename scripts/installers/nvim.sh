#!/usr/bin/env bash
# Neovim installer
# Installs Neovim nightly from GitHub releases

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"

# Configuration
NVIM_VERSION="${NVIM_VERSION:-nightly}"
NVIM_INSTALL_DIR="${NVIM_INSTALL_DIR:-$HOME/.local/nvim}"
NVIM_BIN="$LOCAL_BIN/nvim"

# ============================================================================
# NEOVIM INSTALLATION
# ============================================================================

get_nvim_asset_name() {
    case "$OS-$ARCH" in
        linux-x86_64)  echo "nvim-linux-x86_64.tar.gz";;
        linux-arm64)   echo "nvim-linux-arm64.tar.gz";;
        macos-x86_64)  echo "nvim-macos-x86_64.tar.gz";;
        macos-arm64)   echo "nvim-macos-arm64.tar.gz";;
        *) 
            log_error "Unsupported platform: $OS-$ARCH"
            return 1
            ;;
    esac
}

get_installed_nvim_version() {
    if [[ -x "$NVIM_BIN" ]]; then
        "$NVIM_BIN" --version 2>/dev/null | head -1 | grep -oP 'v\d+\.\d+\.\d+(-\w+)?' || echo "unknown"
    else
        echo "not installed"
    fi
}

install_nvim() {
    local force="${1:-false}"
    
    log_step "Installing Neovim ($NVIM_VERSION)"
    
    # Check if already installed
    if [[ -x "$NVIM_BIN" ]] && [[ "$force" != "true" ]]; then
        local current_version
        current_version="$(get_installed_nvim_version)"
        log_info "Neovim already installed: $current_version"
        
        if is_interactive && ! ask_yes_no "Reinstall anyway?" "n"; then
            return 0
        fi
    fi
    
    local asset
    asset="$(get_nvim_asset_name)" || return 1
    
    local url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${asset}"
    local tmp
    tmp="$(mktemp -d)"
    local tarball="$tmp/$asset"
    
    log_info "Downloading from: $url"
    if ! download_file "$url" "$tarball"; then
        log_error "Failed to download Neovim"
        rm -rf "$tmp"
        return 1
    fi
    
    # Remove old installation
    [[ -d "$NVIM_INSTALL_DIR" ]] && rm -rf "$NVIM_INSTALL_DIR"
    
    # Extract
    log_info "Extracting to $NVIM_INSTALL_DIR..."
    mkdir -p "$NVIM_INSTALL_DIR"
    tar -C "$NVIM_INSTALL_DIR" --strip-components=1 -xzf "$tarball"
    
    # Create symlink
    ensure_dir "$LOCAL_BIN"
    ln -sf "$NVIM_INSTALL_DIR/bin/nvim" "$NVIM_BIN"
    
    # Cleanup
    rm -rf "$tmp"
    
    # Verify
    if [[ -x "$NVIM_BIN" ]]; then
        log_success "Neovim installed: $("$NVIM_BIN" --version | head -1)"
    else
        log_error "Installation failed"
        return 1
    fi
}

uninstall_nvim() {
    log_step "Uninstalling Neovim (nightly)"
    
    if [[ -L "$NVIM_BIN" ]]; then
        local target
        target="$(readlink "$NVIM_BIN")"
        if [[ "$target" == "$NVIM_INSTALL_DIR/"* ]]; then
            rm "$NVIM_BIN"
            log_success "Removed nvim symlink"
        fi
    fi
    
    if [[ -d "$NVIM_INSTALL_DIR" ]]; then
        rm -rf "$NVIM_INSTALL_DIR"
        log_success "Removed $NVIM_INSTALL_DIR"
    fi
}

check_nvim() {
    if [[ -x "$NVIM_BIN" ]]; then
        echo "installed: $(get_installed_nvim_version)"
        return 0
    else
        echo "not installed"
        return 1
    fi
}

# ============================================================================
# NEOVIM DEPENDENCIES
# ============================================================================

# Dependencies for full Neovim functionality based on your config
NVIM_DEPS=(
    git
    curl
    unzip
    tar
    gzip
    gcc
    make
    nodejs
    npm
    python
    pip
    ripgrep
    fd
    luarocks
)

# LSP servers installed via Mason (informational)
NVIM_LSP_SERVERS=(
    clangd
    lua_ls
    # ts_ls
    # html
    # cssls
    # tailwindcss
    pyright
)

# Formatters/linters used by none-ls
NVIM_FORMATTERS=(
    prettier
    stylua
    eslint_d
)

install_nvim_deps() {
    log_step "Installing Neovim dependencies"
    
    local missing=()
    for dep in "${NVIM_DEPS[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All dependencies already installed"
        return 0
    fi
    
    log_info "Missing dependencies: ${missing[*]}"
    
    if is_interactive; then
        mapfile -t to_install < <(select_items "Select dependencies to install:" "${missing[@]}")
    else
        to_install=("${missing[@]}")
    fi
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        install_packages "${to_install[@]}"
    fi
    
    # Ensure fd alias on Debian-based systems
    if command_exists fdfind && ! command_exists fd; then
        ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
        log_success "Created fd alias"
    fi
}

install_nvim_npm_tools() {
    log_step "Installing npm-based tools for Neovim"
    
    if ! command_exists npm; then
        log_warn "npm not found, skipping npm tools"
        return 1
    fi
    
    local tools=(prettier eslint_d)
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All npm tools already installed"
        return 0
    fi
    
    log_info "Installing: ${missing[*]}"
    npm install -g "${missing[@]}"
}

install_nvim_pip_tools() {
    log_step "Installing pip-based tools for Neovim"
    
    local pip_cmd
    if command_exists pip3; then
        pip_cmd="pip3"
    elif command_exists pip; then
        pip_cmd="pip"
    else
        log_warn "pip not found, skipping pip tools"
        return 1
    fi
    
    # pynvim is required for some plugins
    if ! $pip_cmd show pynvim &>/dev/null; then
        log_info "Installing pynvim..."
        $pip_cmd install --user pynvim
    fi
}

setup_nvim_plugins() {
    log_step "Setting up Neovim plugins"
    
    if ! command_exists nvim; then
        log_error "Neovim not found"
        return 1
    fi
    
    log_info "Running Lazy.nvim sync..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    log_success "Plugins synced"
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    cat <<EOF
Neovim Installer

Usage: $(basename "$0") <command> [options]

Commands:
    install         Install Neovim nightly
    uninstall       Remove Neovim nightly installation
    deps            Install system dependencies
    npm-tools       Install npm-based tools (prettier, eslint_d)
    pip-tools       Install pip-based tools (pynvim)
    plugins         Sync Neovim plugins via Lazy.nvim
    check           Check installation status
    all             Install everything (nvim + deps + tools + plugins)
    
Options:
    --force         Force reinstall even if already installed
    --help          Show this help

Environment:
    NVIM_VERSION    Neovim version to install (default: nightly)
EOF
}

main() {
    local cmd="${1:-}"
    local force="false"
    
    # Parse flags
    for arg in "$@"; do
        case "$arg" in
            --force) force="true";;
            --help|-h) show_help; exit 0;;
        esac
    done
    
    case "$cmd" in
        install)
            install_nvim "$force"
            ;;
        uninstall)
            uninstall_nvim
            ;;
        deps)
            install_nvim_deps
            ;;
        npm-tools)
            install_nvim_npm_tools
            ;;
        pip-tools)
            install_nvim_pip_tools
            ;;
        plugins)
            setup_nvim_plugins
            ;;
        check)
            check_nvim
            ;;
        all)
            install_nvim_deps
            install_nvim "$force"
            install_nvim_npm_tools
            install_nvim_pip_tools
            setup_nvim_plugins
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

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
