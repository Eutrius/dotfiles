#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

PACKAGES_FILE="$SCRIPTS_DIR/packages.conf"

get_configs() {
    local in_section=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" == "[configs]" ]]; then
            in_section=1
            continue
        elif [[ "$line" =~ ^\[.*\]$ ]]; then
            in_section=0
            continue
        fi
        
        if ((in_section)); then
            echo "${line%%|*}"
        fi
    done < "$PACKAGES_FILE"
}

get_config_info() {
    local config="$1"
    local in_section=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" == "[configs]" ]]; then
            in_section=1
            continue
        elif [[ "$line" =~ ^\[.*\]$ ]]; then
            in_section=0
            continue
        fi
        
        if ((in_section)) && [[ "$line" == "$config|"* ]]; then
            echo "${line#*|}"
            return 0
        fi
    done < "$PACKAGES_FILE"
    return 1
}

get_config_deps() {
    local config="$1"
    local info
    info="$(get_config_info "$config")" || return 1
    echo "${info%%|*}" | tr ',' ' '
}

get_config_description() {
    local config="$1"
    local info
    info="$(get_config_info "$config")" || return 1
    echo "${info#*|}"
}

get_dependencies() {
    local in_section=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" == "[dependencies]" ]]; then
            in_section=1
            continue
        elif [[ "$line" =~ ^\[.*\]$ ]]; then
            in_section=0
            continue
        fi
        
        if ((in_section)); then
            echo "${line%%|*}"
        fi
    done < "$PACKAGES_FILE"
}

get_dependency_info() {
    local dep="$1"
    local in_section=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" == "[dependencies]" ]]; then
            in_section=1
            continue
        elif [[ "$line" =~ ^\[.*\]$ ]]; then
            in_section=0
            continue
        fi
        
        if ((in_section)) && [[ "$line" == "$dep|"* ]]; then
            echo "$line"
            return 0
        fi
    done < "$PACKAGES_FILE"
    return 1
}

get_dep_field() {
    local dep="$1"
    local field="$2"
    local info
    info="$(get_dependency_info "$dep")" || return 1
    echo "$info" | cut -d'|' -f"$((field+1))"
}

get_dep_min_version()  { get_dep_field "$1" 1; }
get_dep_apt_pkg()      { get_dep_field "$1" 2; }
get_dep_pacman_pkg()   { get_dep_field "$1" 3; }
get_dep_brew_pkg()     { get_dep_field "$1" 4; }
get_dep_dnf_pkg()      { get_dep_field "$1" 5; }
get_dep_github()       { get_dep_field "$1" 6; }
get_dep_asset()        { get_dep_field "$1" 7; }
get_dep_description()  { get_dep_field "$1" 8; }

get_dep_pkg_name() {
    local dep="$1"
    local pm="${2:-$(detect_package_manager)}"
    
    case "$pm" in
        apt)    get_dep_apt_pkg "$dep";;
        pacman) get_dep_pacman_pkg "$dep";;
        brew)   get_dep_brew_pkg "$dep";;
        dnf)    get_dep_dnf_pkg "$dep";;
        *)      echo "$dep";;
    esac
}

get_installed_version() {
    local cmd="$1"
    
    if ! command_exists "$cmd"; then
        echo ""
        return 1
    fi
    
    local version_output
    case "$cmd" in
        nvim|neovim)
            version_output="$(nvim --version 2>/dev/null | head -1)"
            ;;
        fd)
            version_output="$(fd --version 2>/dev/null)"
            ;;
        rg|ripgrep)
            version_output="$(rg --version 2>/dev/null | head -1)"
            ;;
        fzf)
            version_output="$(fzf --version 2>/dev/null)"
            ;;
        zsh)
            version_output="$(zsh --version 2>/dev/null)"
            ;;
        tmux)
            version_output="$(tmux -V 2>/dev/null)"
            ;;
        eza)
            version_output="$(eza --version 2>/dev/null | head -1)"
            ;;
        starship)
            version_output="$(starship --version 2>/dev/null | head -1)"
            ;;
        git)
            version_output="$(git --version 2>/dev/null)"
            ;;
        curl)
            version_output="$(curl --version 2>/dev/null | head -1)"
            ;;
        *)
            version_output="$("$cmd" --version 2>/dev/null | head -1)"
            ;;
    esac
    
    extract_version "$version_output"
}

check_dependency() {
    local dep="$1"
    local cmd="${2:-$dep}"
    
    case "$dep" in
        neovim) cmd="nvim";;
        ripgrep) cmd="rg";;
    esac
    
    local installed_ver
    installed_ver="$(get_installed_version "$cmd")"
    
    if [[ -z "$installed_ver" ]]; then
        return 1
    fi
    
    local min_ver
    min_ver="$(get_dep_min_version "$dep")"
    
    if [[ -n "$min_ver" ]] && ! version_gte "$installed_ver" "$min_ver"; then
        return 2
    fi
    
    return 0
}

install_via_pkg_manager() {
    local pkg="$1"
    local pm="${2:-$(detect_package_manager)}"
    
    [[ -z "$pkg" ]] && return 1
    
    log_info "Installing $pkg via $pm..."
    
    case "$pm" in
        apt)
            run_privileged apt-get update -qq
            run_privileged apt-get install -y "$pkg"
            ;;
        pacman)
            run_privileged pacman -S --noconfirm "$pkg"
            ;;
        brew)
            brew install "$pkg"
            ;;
        dnf)
            run_privileged dnf install -y "$pkg"
            ;;
        *)
            log_error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

install_via_github() {
    local dep="$1"
    local repo="$2"
    local asset_pattern="$3"
    
    [[ -z "$repo" ]] && return 1
    
    log_info "Installing $dep from GitHub ($repo)..."
    
    local version
    version="$(github_latest_version "$repo")"
    [[ -z "$version" ]] && { log_error "Could not get latest version"; return 1; }
    
    local version_num="${version#v}"
    
    local arch="$(detect_arch)"
    local goarch="$(get_go_arch)"
    local nvim_arch="$(get_nvim_arch)"
    local asset="${asset_pattern//\{version\}/$version_num}"
    asset="${asset//\{vversion\}/$version}"
    asset="${asset//\{arch\}/$arch}"
    asset="${asset//\{goarch\}/$goarch}"
    asset="${asset//\{nvim_arch\}/$nvim_arch}"
    
    local url="https://github.com/$repo/releases/download/$version/$asset"
    
    local tmp
    tmp="$(mktemp -d)"
    local archive="$tmp/$asset"
    
    log_info "Downloading $url..."
    if ! download_file "$url" "$archive"; then
        rm -rf "$tmp"
        return 1
    fi
    
    log_info "Extracting..."
    cd "$tmp"
    case "$asset" in
        *.tar.gz|*.tgz)
            tar -xzf "$archive"
            ;;
        *.tar.xz)
            tar -xJf "$archive"
            ;;
        *.zip)
            unzip -q "$archive"
            ;;
    esac
    
    local binary
    case "$dep" in
        neovim)
            local nvim_dir="$LOCAL_SHARE/nvim-install"
            rm -rf "$nvim_dir"
            mv nvim-linux-* "$nvim_dir" 2>/dev/null || mv nvim-macos-* "$nvim_dir" 2>/dev/null
            ln -sf "$nvim_dir/bin/nvim" "$LOCAL_BIN/nvim"
            ;;
        *)
            binary="$(find . -maxdepth 2 -type f -name "$dep" -o -name "${dep}-*" 2>/dev/null | head -1)"
            if [[ -z "$binary" ]]; then
                binary="$(find . -maxdepth 2 -type f -executable 2>/dev/null | grep -v '\.tar' | head -1)"
            fi
            if [[ -n "$binary" ]]; then
                chmod +x "$binary"
                cp "$binary" "$LOCAL_BIN/$dep"
            fi
            ;;
    esac
    
    cd - >/dev/null
    rm -rf "$tmp"
    
    if command_exists "$dep" || [[ -x "$LOCAL_BIN/$dep" ]]; then
        log_success "$dep installed from GitHub"
        return 0
    else
        log_error "Failed to install $dep from GitHub"
        return 1
    fi
}

install_dependency() {
    local dep="$1"
    local force="${2:-false}"
    
    local cmd="$dep"
    case "$dep" in
        neovim) cmd="nvim";;
        ripgrep) cmd="rg";;
    esac
    
    local status
    check_dependency "$dep" "$cmd"
    status=$?
    
    if [[ "$status" -eq 0 ]] && [[ "$force" != "true" ]]; then
        local ver="$(get_installed_version "$cmd")"
        log_info "$dep $ver already installed"
        return 0
    fi
    
    local min_ver="$(get_dep_min_version "$dep")"
    local pkg_name="$(get_dep_pkg_name "$dep")"
    local github="$(get_dep_github "$dep")"
    local asset="$(get_dep_asset "$dep")"
    
    if [[ -n "$pkg_name" ]]; then
        if install_via_pkg_manager "$pkg_name"; then
            local installed_ver="$(get_installed_version "$cmd")"
            if [[ -n "$min_ver" ]] && ! version_gte "$installed_ver" "$min_ver"; then
                log_warn "$dep $installed_ver is below minimum $min_ver"
                log_info "Will try GitHub install instead..."
            else
                log_success "$dep installed via package manager"
                return 0
            fi
        fi
    fi
    
    if [[ -n "$github" ]] && [[ -n "$asset" ]]; then
        install_via_github "$dep" "$github" "$asset"
        return $?
    fi
    
    log_error "Could not install $dep"
    return 1
}

uninstall_github_dep() {
    local dep="$1"
    
    case "$dep" in
        neovim)
            rm -f "$LOCAL_BIN/nvim"
            rm -rf "$LOCAL_SHARE/nvim-install"
            ;;
        *)
            rm -f "$LOCAL_BIN/$dep"
            ;;
    esac
    
    log_success "$dep removed"
}

get_configs_display() {
    local configs
    mapfile -t configs < <(get_configs)
    
    for cfg in "${configs[@]}"; do
        local desc="$(get_config_description "$cfg")"
        local dest="$CONFIG_DIR/$cfg"
        local status_icon
        
        if [[ -L "$dest" ]]; then
            status_icon="${GREEN}✓${NC}"
        elif [[ -e "$dest" ]]; then
            status_icon="${YELLOW}!${NC}"
        else
            status_icon="${RED}✗${NC}"
        fi
        
        printf "%b %s - %s\n" "$status_icon" "$cfg" "$desc"
    done
}

get_dependencies_display() {
    local deps
    mapfile -t deps < <(get_dependencies)
    
    for dep in "${deps[@]}"; do
        local desc="$(get_dep_description "$dep")"
        local status_icon dep_status
        local cmd="$dep"
        case "$dep" in
            neovim) cmd="nvim";;
            ripgrep) cmd="rg";;
        esac
        
        check_dependency "$dep" "$cmd" && dep_status=0 || dep_status=$?
        case $dep_status in
            0) status_icon="${GREEN}✓${NC}";;
            1) status_icon="${RED}✗${NC}";;
            2) status_icon="${YELLOW}↓${NC}";;
        esac
        
        printf "%b %s - %s\n" "$status_icon" "$dep" "$desc"
    done
}
