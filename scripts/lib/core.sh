#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()    { printf "${CYAN}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
log_step()    { printf "\n${BOLD}${CYAN}==> %s${NC}\n" "$*"; }
log_debug()   { [[ "${DEBUG:-0}" == "1" ]] && printf "${DIM}[DEBUG] %s${NC}\n" "$*"; }

detect_os() {
    case "$(uname -s)" in
        Linux)  echo "linux";;
        Darwin) echo "macos";;
        *)      echo "unknown";;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)   echo "x86_64";;
        aarch64|arm64)  echo "aarch64";;
        armv7l)         echo "armv7";;
        *)              echo "unknown";;
    esac
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    elif command -v sw_vers &>/dev/null; then
        echo "macos"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    if command -v pacman &>/dev/null; then echo "pacman"
    elif command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v brew &>/dev/null; then echo "brew"
    elif command -v zypper &>/dev/null; then echo "zypper"
    else echo "unknown"
    fi
}

get_go_arch() {
    case "$(detect_arch)" in
        x86_64)  echo "amd64";;
        aarch64) echo "arm64";;
        armv7)   echo "arm";;
        *)       echo "amd64";;
    esac
}

get_nvim_arch() {
    case "$(detect_arch)" in
        x86_64)  echo "x86_64";;
        aarch64) echo "arm64";;
        armv7)   echo "arm64";;
        *)       echo "x86_64";;
    esac
}

command_exists() {
    command -v "$1" &>/dev/null
}

ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1"
}

is_interactive() {
    [[ -t 0 ]] && [[ -t 1 ]]
}

run_privileged() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif command_exists sudo; then
        sudo "$@"
    elif command_exists doas; then
        doas "$@"
    else
        log_error "No privilege escalation available (sudo/doas)"
        return 1
    fi
}

version_gte() {
    local v1="$1" v2="$2"
    [[ -z "$v2" ]] && return 0
    printf '%s\n%s\n' "$v2" "$v1" | sort -V -C
}

extract_version() {
    echo "$1" | grep -oP '\d+\.\d+(\.\d+)?' | head -1
}

download_file() {
    local url="$1" output="$2"
    ensure_dir "$(dirname "$output")"
    
    if command_exists curl; then
        curl -fsSL "$url" -o "$output"
    elif command_exists wget; then
        wget -qO "$output" "$url"
    else
        log_error "No download tool available (curl/wget)"
        return 1
    fi
}

github_latest_version() {
    local repo="$1"
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    
    if command_exists curl; then
        curl -fsSL "$api_url" 2>/dev/null | grep -Po '"tag_name": *"\K[^"]+' || echo ""
    elif command_exists wget; then
        wget -qO- "$api_url" 2>/dev/null | grep -Po '"tag_name": *"\K[^"]+' || echo ""
    fi
}

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"
SYSTEM_FILE="$DOTFILES_DIR/.system"

ensure_dir "$LOCAL_BIN"

[[ ":$PATH:" != *":$LOCAL_BIN:"* ]] && export PATH="$LOCAL_BIN:$PATH" || true
