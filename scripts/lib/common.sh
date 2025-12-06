#!/usr/bin/env bash
# Common utilities for dotfiles scripts
# Source this file in other scripts

set -euo pipefail

# ============================================================================
# COLORS
# ============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m'

# ============================================================================
# LOGGING
# ============================================================================
log_info()    { printf "${CYAN}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log_step()    { printf "\n${BOLD}${CYAN}==> %s${NC}\n" "$*"; }

# ============================================================================
# OS/ARCH DETECTION
# ============================================================================
detect_os() {
    local os
    os="$(uname -s)"
    case "$os" in
        Linux)  echo "linux";;
        Darwin) echo "macos";;
        *)      echo "unknown";;
    esac
}

detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)   echo "x86_64";;
        aarch64|arm64)  echo "arm64";;
        armv7l)         echo "armv7";;
        *)              echo "unknown";;
    esac
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "${ID:-unknown}"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif command -v sw_vers &>/dev/null; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# ============================================================================
# PACKAGE MANAGER DETECTION
# ============================================================================
detect_package_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v brew &>/dev/null; then
        echo "brew"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# ============================================================================
# PRIVILEGE ESCALATION
# ============================================================================
run_privileged() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif command -v sudo &>/dev/null; then
        sudo "$@"
    elif command -v doas &>/dev/null; then
        doas "$@"
    else
        log_error "No privilege escalation method found (sudo/doas)"
        return 1
    fi
}

# ============================================================================
# COMMAND CHECKS
# ============================================================================
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if running in interactive mode
is_interactive() {
    [[ -t 0 ]] && [[ "${INTERACTIVE:-1}" == "1" ]]
}

# ============================================================================
# USER INPUT
# ============================================================================
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    
    if ! is_interactive; then
        [[ "$default" == "y" ]]
        return
    fi
    
    local answer
    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n] " answer
        [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
    else
        read -rp "$prompt [y/N] " answer
        [[ "$answer" =~ ^[Yy] ]]
    fi
}

# Select items from a list
# Usage: selected=($(select_items "prompt" "${items[@]}"))
select_items() {
    local prompt="$1"
    shift
    local items=("$@")
    
    if ! is_interactive; then
        printf '%s\n' "${items[@]}"
        return
    fi
    
    printf "\n${BOLD}%s${NC}\n" "$prompt"
    printf "(Enter numbers separated by space, 'a' for all, 'n' for none)\n\n"
    
    local i
    for i in "${!items[@]}"; do
        printf "  %2d) %s\n" "$((i+1))" "${items[i]}"
    done
    
    printf "\n"
    local selection
    read -rp "Selection: " selection
    
    if [[ "$selection" == "a" || "$selection" == "all" ]]; then
        printf '%s\n' "${items[@]}"
        return
    fi
    
    if [[ "$selection" == "n" || "$selection" == "none" || -z "$selection" ]]; then
        return
    fi
    
    local idx
    for idx in $selection; do
        if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#items[@]} )); then
            printf '%s\n' "${items[idx-1]}"
        fi
    done
}

# ============================================================================
# PATH UTILITIES
# ============================================================================
ensure_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

# Get the dotfiles root directory
get_dotfiles_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    # Navigate up from scripts/lib to dotfiles root
    echo "$(cd "$script_dir/../.." && pwd)"
}

# ============================================================================
# VERSION COMPARISON
# ============================================================================
version_gte() {
    # Returns 0 if $1 >= $2
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# ============================================================================
# DOWNLOAD UTILITIES
# ============================================================================
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -fsSL --retry 3 --retry-delay 2 -o "$output" "$url"
    elif command_exists wget; then
        wget -q --tries=3 -O "$output" "$url"
    else
        log_error "Neither curl nor wget found"
        return 1
    fi
}

# Get latest release tag from GitHub API
get_latest_github_release() {
    local repo="$1"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    
    if command_exists curl; then
        curl -fsSL "$api_url" 2>/dev/null | grep -Po '"tag_name": *"\K[^"]+' || echo ""
    elif command_exists wget; then
        wget -qO- "$api_url" 2>/dev/null | grep -Po '"tag_name": *"\K[^"]+' || echo ""
    else
        echo ""
    fi
}

# ============================================================================
# GIT UTILITIES
# ============================================================================
git_clone_or_pull() {
    local repo="$1"
    local dest="$2"
    local depth="${3:-}"
    
    if [[ -d "$dest/.git" ]]; then
        log_info "Updating $dest..."
        git -C "$dest" pull --ff-only 2>/dev/null || true
    else
        log_info "Cloning $repo..."
        if [[ -n "$depth" ]]; then
            git clone --depth "$depth" "$repo" "$dest"
        else
            git clone "$repo" "$dest"
        fi
    fi
}

# ============================================================================
# EXPORTS FOR SCRIPTS
# ============================================================================
export OS="$(detect_os)"
export ARCH="$(detect_arch)"
export DISTRO="$(detect_distro)"
export PKG_MANAGER="$(detect_package_manager)"
export DOTFILES_DIR="${DOTFILES_DIR:-$(get_dotfiles_dir)}"
export LOCAL_BIN="$HOME/.local/bin"
export LOCAL_SHARE="$HOME/.local/share"

# Ensure local bin exists and is in PATH
ensure_dir "$LOCAL_BIN"
[[ ":$PATH:" != *":$LOCAL_BIN:"* ]] && export PATH="$LOCAL_BIN:$PATH"
