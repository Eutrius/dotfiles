#!/usr/bin/env bash
# Package manager abstraction layer
# Provides unified interface for installing packages across different systems

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# PACKAGE NAME MAPPING
# Maps generic package names to distro-specific names
# ============================================================================
declare -A PKG_MAP_PACMAN=(
    [fd]="fd"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [eza]="eza"
    [zsh]="zsh"
    [tmux]="tmux"
    [git]="git"
    [curl]="curl"
    [wget]="wget"
    [gcc]="gcc"
    [make]="make"
    [nodejs]="nodejs"
    [npm]="npm"
    [python]="python"
    [pip]="python-pip"
    [unzip]="unzip"
    [tar]="tar"
    [gzip]="gzip"
    [luarocks]="luarocks"
    [tree-sitter]="tree-sitter"
    [lazygit]="lazygit"
    [gdb]="gdb"
)

declare -A PKG_MAP_APT=(
    [fd]="fd-find"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [eza]="MANUAL"  # Not in default repos
    [zsh]="zsh"
    [tmux]="tmux"
    [git]="git"
    [curl]="curl"
    [wget]="wget"
    [gcc]="gcc"
    [make]="make"
    [nodejs]="nodejs"
    [npm]="npm"
    [python]="python3"
    [pip]="python3-pip"
    [unzip]="unzip"
    [tar]="tar"
    [gzip]="gzip"
    [luarocks]="luarocks"
    [tree-sitter]="MANUAL"
    [lazygit]="MANUAL"
    [gdb]="gdb"
)

declare -A PKG_MAP_DNF=(
    [fd]="fd-find"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [eza]="eza"
    [zsh]="zsh"
    [tmux]="tmux"
    [git]="git"
    [curl]="curl"
    [wget]="wget"
    [gcc]="gcc"
    [make]="make"
    [nodejs]="nodejs"
    [npm]="npm"
    [python]="python3"
    [pip]="python3-pip"
    [unzip]="unzip"
    [tar]="tar"
    [gzip]="gzip"
    [luarocks]="luarocks"
    [tree-sitter]="MANUAL"
    [lazygit]="MANUAL"
    [gdb]="gdb"
)

declare -A PKG_MAP_BREW=(
    [fd]="fd"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [eza]="eza"
    [zsh]="zsh"
    [tmux]="tmux"
    [git]="git"
    [curl]="curl"
    [wget]="wget"
    [gcc]="gcc"
    [make]="make"
    [nodejs]="node"
    [npm]="npm"
    [python]="python"
    [pip]="SKIP"  # Comes with python
    [unzip]="unzip"
    [tar]="gnu-tar"
    [gzip]="gzip"
    [luarocks]="luarocks"
    [tree-sitter]="tree-sitter"
    [lazygit]="lazygit"
    [gdb]="gdb"
)

# ============================================================================
# PACKAGE MANAGER OPERATIONS
# ============================================================================

pkg_update_cache() {
    case "$PKG_MANAGER" in
        pacman) run_privileged pacman -Sy;;
        apt)    run_privileged apt-get update;;
        dnf)    run_privileged dnf check-update || true;;
        brew)   brew update;;
        *)      log_warn "Unknown package manager: $PKG_MANAGER";;
    esac
}

pkg_install() {
    local packages=("$@")
    [[ ${#packages[@]} -eq 0 ]] && return 0
    
    case "$PKG_MANAGER" in
        pacman) run_privileged pacman -S --needed --noconfirm "${packages[@]}";;
        apt)    run_privileged apt-get install -y --no-install-recommends "${packages[@]}";;
        dnf)    run_privileged dnf install -y "${packages[@]}";;
        yum)    run_privileged yum install -y "${packages[@]}";;
        brew)   brew install "${packages[@]}";;
        zypper) run_privileged zypper install -y "${packages[@]}";;
        *)      log_error "Unknown package manager: $PKG_MANAGER"; return 1;;
    esac
}

pkg_remove() {
    local packages=("$@")
    [[ ${#packages[@]} -eq 0 ]] && return 0
    
    case "$PKG_MANAGER" in
        pacman) run_privileged pacman -Rs --noconfirm "${packages[@]}";;
        apt)    run_privileged apt-get remove -y "${packages[@]}";;
        dnf)    run_privileged dnf remove -y "${packages[@]}";;
        yum)    run_privileged yum remove -y "${packages[@]}";;
        brew)   brew uninstall "${packages[@]}";;
        zypper) run_privileged zypper remove -y "${packages[@]}";;
        *)      log_error "Unknown package manager: $PKG_MANAGER"; return 1;;
    esac
}

# Get the distro-specific package name
get_pkg_name() {
    local generic_name="$1"
    local pkg_name
    
    case "$PKG_MANAGER" in
        pacman) pkg_name="${PKG_MAP_PACMAN[$generic_name]:-$generic_name}";;
        apt)    pkg_name="${PKG_MAP_APT[$generic_name]:-$generic_name}";;
        dnf|yum) pkg_name="${PKG_MAP_DNF[$generic_name]:-$generic_name}";;
        brew)   pkg_name="${PKG_MAP_BREW[$generic_name]:-$generic_name}";;
        *)      pkg_name="$generic_name";;
    esac
    
    echo "$pkg_name"
}

# Check if a generic package is installed
pkg_is_installed() {
    local generic_name="$1"
    local pkg_name
    pkg_name="$(get_pkg_name "$generic_name")"
    
    # Special cases
    case "$pkg_name" in
        MANUAL|SKIP) return 1;;
    esac
    
    case "$PKG_MANAGER" in
        pacman) pacman -Qi "$pkg_name" &>/dev/null;;
        apt)    dpkg -s "$pkg_name" &>/dev/null;;
        dnf|yum) rpm -q "$pkg_name" &>/dev/null;;
        brew)   brew list "$pkg_name" &>/dev/null;;
        *)      command_exists "$generic_name";;
    esac
}

# Install packages by generic names, handles mapping
install_packages() {
    local generic_names=("$@")
    local to_install=()
    local manual_install=()
    
    for name in "${generic_names[@]}"; do
        local pkg_name
        pkg_name="$(get_pkg_name "$name")"
        
        case "$pkg_name" in
            MANUAL)
                manual_install+=("$name")
                ;;
            SKIP)
                log_info "Skipping $name (not needed on this system)"
                ;;
            *)
                to_install+=("$pkg_name")
                ;;
        esac
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing via $PKG_MANAGER: ${to_install[*]}"
        pkg_install "${to_install[@]}"
    fi
    
    if [[ ${#manual_install[@]} -gt 0 ]]; then
        log_warn "These packages require manual installation: ${manual_install[*]}"
        for pkg in "${manual_install[@]}"; do
            install_manual "$pkg"
        done
    fi
}

# Handle manual installations for packages not in repos
install_manual() {
    local pkg="$1"
    
    case "$pkg" in
        eza)
            install_eza_manual
            ;;
        tree-sitter)
            install_tree_sitter_manual
            ;;
        lazygit)
            install_lazygit_manual
            ;;
        *)
            log_warn "No manual installation method for: $pkg"
            ;;
    esac
}

# ============================================================================
# MANUAL INSTALLATION FUNCTIONS
# ============================================================================

install_eza_manual() {
    if command_exists eza; then
        log_info "eza already installed"
        return 0
    fi
    
    log_info "Installing eza..."
    
    if command_exists cargo; then
        cargo install eza
    else
        # Download from GitHub releases
        local version="v0.18.0"
        local archive="eza_${ARCH}-unknown-linux-gnu.tar.gz"
        local url="https://github.com/eza-community/eza/releases/download/${version}/${archive}"
        local tmp
        tmp="$(mktemp -d)"
        
        download_file "$url" "$tmp/$archive"
        tar -C "$tmp" -xzf "$tmp/$archive"
        install -m755 "$tmp/eza" "$LOCAL_BIN/eza"
        rm -rf "$tmp"
    fi
    
    log_success "eza installed"
}

install_tree_sitter_manual() {
    if command_exists tree-sitter; then
        log_info "tree-sitter already installed"
        return 0
    fi
    
    log_info "Installing tree-sitter CLI..."
    
    local version="v0.22.6"
    local archive
    
    case "$OS-$ARCH" in
        linux-x86_64)  archive="tree-sitter-linux-x64.gz";;
        linux-arm64)   archive="tree-sitter-linux-arm64.gz";;
        macos-x86_64)  archive="tree-sitter-macos-x64.gz";;
        macos-arm64)   archive="tree-sitter-macos-arm64.gz";;
        *) log_error "Unsupported platform: $OS-$ARCH"; return 1;;
    esac
    
    local url="https://github.com/tree-sitter/tree-sitter/releases/download/${version}/${archive}"
    local tmp
    tmp="$(mktemp -d)"
    
    download_file "$url" "$tmp/$archive"
    gunzip "$tmp/$archive"
    install -m755 "$tmp/tree-sitter-"* "$LOCAL_BIN/tree-sitter"
    rm -rf "$tmp"
    
    log_success "tree-sitter installed"
}

install_lazygit_manual() {
    if command_exists lazygit; then
        log_info "lazygit already installed"
        return 0
    fi
    
    log_info "Installing lazygit..."
    
    local version="v0.41.0"
    local archive
    
    case "$OS-$ARCH" in
        linux-x86_64)  archive="lazygit_${version#v}_Linux_x86_64.tar.gz";;
        linux-arm64)   archive="lazygit_${version#v}_Linux_arm64.tar.gz";;
        macos-x86_64)  archive="lazygit_${version#v}_Darwin_x86_64.tar.gz";;
        macos-arm64)   archive="lazygit_${version#v}_Darwin_arm64.tar.gz";;
        *) log_error "Unsupported platform: $OS-$ARCH"; return 1;;
    esac
    
    local url="https://github.com/jesseduffield/lazygit/releases/download/${version}/${archive}"
    local tmp
    tmp="$(mktemp -d)"
    
    download_file "$url" "$tmp/$archive"
    tar -C "$tmp" -xzf "$tmp/$archive"
    install -m755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
    rm -rf "$tmp"
    
    log_success "lazygit installed"
}
