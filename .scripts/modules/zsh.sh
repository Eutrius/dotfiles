#!/usr/bin/env bash

set -euo pipefail

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"

ZSH_BUILD_VERSION="${ZSH_BUILD_VERSION:-5.9}"
NCURSES_VERSION="${NCURSES_VERSION:-6.4}"

PREFIX="${PREFIX:-$HOME/.local}"
BUILD_DIR=""
NPROC="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

_zsh_cleanup() { [[ -n "$BUILD_DIR" ]] && rm -rf "$BUILD_DIR"; }

_zsh_log() { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
_zsh_err() { printf "\033[1;31mError:\033[0m %s\n" "$*" >&2; return 1; }
_zsh_ok()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

_zsh_check_deps() {
    local missing=()
    for cmd in gcc make curl tar; do
        command -v "$cmd" >/dev/null || missing+=("$cmd")
    done
    [[ ${#missing[@]} -gt 0 ]] && _zsh_err "Missing: ${missing[*]}. Install build-essential and curl"
}

_zsh_download() {
    local url="$1" out="$2"
    curl -fsSL "$url" -o "$out" || _zsh_err "Failed to download $url"
}

_zsh_build_ncurses() {
    if pkg-config --exists ncurses 2>/dev/null || pkg-config --exists ncursesw 2>/dev/null; then
        _zsh_log "ncurses found (system)"
        return 0
    fi
    if [[ -f "$PREFIX/lib/libncurses.a" ]]; then
        _zsh_log "ncurses found (local)"
        return 0
    fi
    
    _zsh_log "Building ncurses $NCURSES_VERSION"
    cd "$BUILD_DIR"
    _zsh_download "https://ftp.gnu.org/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz" ncurses.tar.gz
    tar -xzf ncurses.tar.gz
    cd ncurses-"$NCURSES_VERSION"
    ./configure --prefix="$PREFIX" --with-shared --with-termlib \
        --enable-pc-files --with-pkg-config-libdir="$PREFIX/lib/pkgconfig" >/dev/null
    make -j"$NPROC" >/dev/null
    make install >/dev/null
}

_zsh_build() {
    _zsh_log "Building zsh $ZSH_BUILD_VERSION"
    cd "$BUILD_DIR"
    _zsh_download "https://sourceforge.net/projects/zsh/files/zsh/$ZSH_BUILD_VERSION/zsh-$ZSH_BUILD_VERSION.tar.xz/download" zsh.tar.xz
    tar -xJf zsh.tar.xz
    cd zsh-"$ZSH_BUILD_VERSION"
    
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}" \
    CFLAGS="-I$PREFIX/include" \
    LDFLAGS="-L$PREFIX/lib" \
    ./configure --prefix="$PREFIX" >/dev/null
    
    make -j"$NPROC" >/dev/null
    make install >/dev/null
}

zsh_build() {
    _zsh_log "zsh $ZSH_BUILD_VERSION installer"
    
    if [[ -x "$PREFIX/bin/zsh" ]]; then
        local cur
        cur="$("$PREFIX/bin/zsh" --version 2>/dev/null | grep -oP '[\d.]+' | head -1)" || true
        if [[ "$cur" == "$ZSH_BUILD_VERSION" ]]; then
            _zsh_ok "zsh $ZSH_BUILD_VERSION already installed"
            return 0
        fi
    fi
    
    _zsh_check_deps
    mkdir -p "$PREFIX/bin"
    
    BUILD_DIR="$(mktemp -d)"
    trap _zsh_cleanup EXIT
    
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    
    _zsh_build_ncurses
    _zsh_build
    
    if [[ -x "$PREFIX/bin/zsh" ]]; then
        _zsh_ok "zsh $ZSH_BUILD_VERSION installed to $PREFIX/bin/zsh"
        "$PREFIX/bin/zsh" --version
        return 0
    else
        _zsh_err "Build failed"
        return 1
    fi
}

zsh_remove() {
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    rm -f "$install_bin/zsh"
}

zsh_version() {
    zsh --version 2>/dev/null | head -1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    zsh_build "$@"
fi
