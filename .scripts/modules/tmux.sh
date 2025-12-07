#!/usr/bin/env bash

set -euo pipefail

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/core.sh"

TMUX_VERSION="${TMUX_VERSION:-3.5a}"
LIBEVENT_VERSION="${LIBEVENT_VERSION:-2.1.12-stable}"
NCURSES_VERSION="${NCURSES_VERSION:-6.4}"

PREFIX="${PREFIX:-$HOME/.local}"
BUILD_DIR=""
NPROC="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

_tmux_cleanup() { [[ -n "$BUILD_DIR" ]] && rm -rf "$BUILD_DIR"; }

_tmux_log() { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
_tmux_err() { printf "\033[1;31mError:\033[0m %s\n" "$*" >&2; return 1; }
_tmux_ok()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }

_tmux_check_deps() {
    local missing=()
    for cmd in gcc make curl tar; do
        command -v "$cmd" >/dev/null || missing+=("$cmd")
    done
    [[ ${#missing[@]} -gt 0 ]] && _tmux_err "Missing: ${missing[*]}. Install build-essential and curl"
}

_tmux_download() {
    local url="$1" out="$2"
    curl -fsSL "$url" -o "$out" || _tmux_err "Failed to download $url"
}

_build_libevent() {
    if pkg-config --exists libevent 2>/dev/null; then
        _tmux_log "libevent found (system)"
        return 0
    fi
    if [[ -f "$PREFIX/lib/libevent.a" ]]; then
        _tmux_log "libevent found (local)"
        return 0
    fi
    
    _tmux_log "Building libevent $LIBEVENT_VERSION"
    cd "$BUILD_DIR"
    _tmux_download "https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VERSION/libevent-$LIBEVENT_VERSION.tar.gz" libevent.tar.gz
    tar -xzf libevent.tar.gz
    cd libevent-"$LIBEVENT_VERSION"
    ./configure --prefix="$PREFIX" --disable-shared --disable-openssl >/dev/null
    make -j"$NPROC" >/dev/null
    make install >/dev/null
}

_build_ncurses() {
    if pkg-config --exists ncurses 2>/dev/null || pkg-config --exists ncursesw 2>/dev/null; then
        _tmux_log "ncurses found (system)"
        return 0
    fi
    if [[ -f "$PREFIX/lib/libncurses.a" ]]; then
        _tmux_log "ncurses found (local)"
        return 0
    fi
    
    _tmux_log "Building ncurses $NCURSES_VERSION"
    cd "$BUILD_DIR"
    _tmux_download "https://ftp.gnu.org/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz" ncurses.tar.gz
    tar -xzf ncurses.tar.gz
    cd ncurses-"$NCURSES_VERSION"
    ./configure --prefix="$PREFIX" --with-shared --with-termlib \
        --enable-pc-files --with-pkg-config-libdir="$PREFIX/lib/pkgconfig" >/dev/null
    make -j"$NPROC" >/dev/null
    make install >/dev/null
}

_build_tmux() {
    _tmux_log "Building tmux $TMUX_VERSION"
    cd "$BUILD_DIR"
    _tmux_download "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz" tmux.tar.gz
    tar -xzf tmux.tar.gz
    cd tmux-"$TMUX_VERSION"
    
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}" \
    CFLAGS="-I$PREFIX/include" \
    LDFLAGS="-L$PREFIX/lib" \
    ./configure --prefix="$PREFIX" >/dev/null
    
    make -j"$NPROC" >/dev/null
    make install >/dev/null
}

tmux_build() {
    _tmux_log "tmux $TMUX_VERSION installer"
    
    if [[ -x "$PREFIX/bin/tmux" ]]; then
        local cur
        cur="$("$PREFIX/bin/tmux" -V 2>/dev/null | grep -oP '[\d.]+\w?' | head -1)" || true
        if [[ "$cur" == "$TMUX_VERSION" ]]; then
            _tmux_ok "tmux $TMUX_VERSION already installed"
            return 0
        fi
    fi
    
    _tmux_check_deps
    mkdir -p "$PREFIX/bin"
    
    BUILD_DIR="$(mktemp -d)"
    trap _tmux_cleanup EXIT
    
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    
    _build_libevent
    _build_ncurses
    _build_tmux
    
    if [[ -x "$PREFIX/bin/tmux" ]]; then
        _tmux_ok "tmux $TMUX_VERSION installed to $PREFIX/bin/tmux"
        "$PREFIX/bin/tmux" -V
        return 0
    else
        _tmux_err "Build failed"
        return 1
    fi
}

tmux_remove() {
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    rm -f "$install_bin/tmux"
}

tmux_version() {
    tmux -V 2>/dev/null
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    tmux_build "$@"
fi
