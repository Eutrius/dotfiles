#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
[[ -z "${REGISTRY_FILE:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/packages.sh"

_load_module() {
    local pkg="$1"
    local module
    
    module="$(get_prog_module "$pkg")"
    [[ -z "$module" ]] && module="$(get_dep_module "$pkg")"
    
    if [[ -n "$module" ]]; then
        local module_file="$SCRIPTS_DIR/modules/${module}.sh"
        if [[ -f "$module_file" ]]; then
            source "$module_file"
            return 0
        fi
    fi
    return 1
}

get_installed_version() {
    local cmd="$1"
    local pkg="${2:-$cmd}"
    
    if ! command_exists "$cmd"; then
        echo ""
        return 1
    fi
    
    local version_output=""
    
    if _load_module "$pkg"; then
        local func="${pkg}_version"
        if declare -f "$func" &>/dev/null; then
            version_output="$("$func" 2>/dev/null)" || true
        fi
    fi
    
    if [[ -z "$version_output" ]]; then
        version_output="$("$cmd" --version 2>/dev/null | head -1)"
        [[ -z "$version_output" ]] && version_output="$("$cmd" -V 2>/dev/null | head -1)"
        [[ -z "$version_output" ]] && version_output="$("$cmd" -v 2>/dev/null | head -1)"
    fi
    
    extract_version "$version_output"
}

check_dependency() {
    local dep="$1"
    local cmd="$(get_cmd_name "$dep")"
    
    local installed_ver
    installed_ver="$(get_installed_version "$cmd" "$dep")"
    
    if [[ -z "$installed_ver" ]]; then
        return 1
    fi
    
    local min_ver
    min_ver="$(get_dep_min_version "$dep")"
    [[ -z "$min_ver" ]] && min_ver="$(get_prog_min_version "$dep")"
    
    if [[ -n "$min_ver" ]] && ! version_gte "$installed_ver" "$min_ver"; then
        return 2
    fi
    
    return 0
}

get_pkg_manager_version() {
    local pkg="$1"
    local pm="${2:-$(detect_package_manager)}"
    
    [[ -z "$pkg" ]] && return 1
    
    local version=""
    case "$pm" in
        apt)
            version="$(apt-cache policy "$pkg" 2>/dev/null | grep 'Candidate:' | awk '{print $2}' | sed 's/-.*$//' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
            ;;
        pacman)
            version="$(pacman -Si "$pkg" 2>/dev/null | grep 'Version' | awk '{print $3}' | sed 's/-.*$//' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
            ;;
        brew)
            version="$(brew info "$pkg" 2>/dev/null | head -1 | awk '{print $3}' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
            ;;
        dnf)
            version="$(dnf info "$pkg" 2>/dev/null | grep 'Version' | head -1 | awk '{print $3}' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
            ;;
    esac
    
    echo "$version"
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

_expand_asset_pattern() {
    local asset_pattern="$1"
    local version="$2"
    local version_num="${version#v}"
    
    local arch="$(detect_arch)"
    local goarch="$(get_go_arch)"
    local nvim_arch="$(get_nvim_arch)"
    local rg_libc="$(get_rg_libc)"
    
    local asset="${asset_pattern//\{version\}/$version_num}"
    asset="${asset//\{vversion\}/$version}"
    asset="${asset//\{arch\}/$arch}"
    asset="${asset//\{goarch\}/$goarch}"
    asset="${asset//\{nvim_arch\}/$nvim_arch}"
    asset="${asset//\{rg_libc\}/$rg_libc}"
    
    echo "$asset"
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
    
    local asset
    asset="$(_expand_asset_pattern "$asset_pattern" "$version")"
    
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
    
    local bin_name="$(get_cmd_name "$dep")"
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    local install_share="${SHARE_PATH:-$LOCAL_SHARE}"
    
    if _load_module "$dep"; then
        local func="${dep}_install"
        if declare -f "$func" &>/dev/null; then
            "$func" "$version"
            local result=$?
            cd - >/dev/null
            rm -rf "$tmp"
            if [[ $result -eq 0 ]]; then
                log_success "$dep installed from GitHub"
                return 0
            fi
            return $result
        fi
    fi
    
    local binary
    binary="$(find . -type f -name "$bin_name" 2>/dev/null | head -1)"
    if [[ -z "$binary" ]]; then
        binary="$(find . -type f -executable -name "$bin_name*" 2>/dev/null | grep -v '\.tar' | head -1)"
    fi
    if [[ -z "$binary" ]]; then
        binary="$(find . -type f -executable 2>/dev/null | grep -v '\.tar' | head -1)"
    fi
    if [[ -n "$binary" ]]; then
        chmod +x "$binary"
        run_privileged cp "$binary" "$install_bin/$bin_name"
    fi
    
    cd - >/dev/null
    rm -rf "$tmp"
    
    if command_exists "$bin_name" || [[ -x "$install_bin/$bin_name" ]]; then
        log_success "$dep installed from GitHub"
        return 0
    else
        log_error "Failed to install $dep from GitHub"
        return 1
    fi
}

install_via_build() {
    local dep="$1"
    
    if _load_module "$dep"; then
        local func="${dep}_build"
        if declare -f "$func" &>/dev/null; then
            "$func"
            return $?
        fi
    fi
    
    local build_script="$SCRIPTS_DIR/build/${dep}.sh"
    if [[ -x "$build_script" ]]; then
        "$build_script"
        return $?
    fi
    
    log_error "No build script for $dep"
    return 1
}

install_dependency() {
    local dep="$1"
    local force="${2:-false}"
    
    local cmd="$(get_cmd_name "$dep")"
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    
    # Check if already installed
    local status
    check_dependency "$dep"
    status=$?
    
    if [[ "$status" -eq 0 ]]; then
        local ver="$(get_installed_version "$cmd" "$dep")"
        
        # Check if installed in our managed locations
        if [[ -e "/usr/local/bin/$cmd" ]] || [[ -L "/usr/local/bin/$cmd" ]] || \
           [[ -e "$install_bin/$cmd" ]] || [[ -L "$install_bin/$cmd" ]]; then
            if [[ "$force" != "true" ]]; then
                log_info "$dep $ver already installed"
                return 0
            fi
        else
            # Installed elsewhere
            log_info "$dep $ver already installed at $(command -v "$cmd")"
            if [[ "$force" == "true" ]]; then
                log_info "Reinstalling to managed location..."
            else
                return 0
            fi
        fi
    fi
    
    # If forcing reinstall and command exists, remove first
    if [[ "$force" == "true" ]] && command_exists "$cmd"; then
        local install_bin_exists=false
        local usr_local_exists=false
        
        [[ -e "/usr/local/bin/$cmd" ]] || [[ -L "/usr/local/bin/$cmd" ]] && usr_local_exists=true
        [[ -e "$install_bin/$cmd" ]] || [[ -L "$install_bin/$cmd" ]] && install_bin_exists=true
        
        # Only remove if it's in managed locations
        if [[ "$usr_local_exists" == "true" ]] || [[ "$install_bin_exists" == "true" ]]; then
            log_info "Removing existing $dep before reinstall..."
            remove_dependency "$dep" >/dev/null 2>&1 || true
        fi
    fi
    
    local min_ver="$(get_dep_min_version "$dep")"
    local pkg_name="$(get_dep_pkg_name "$dep")"
    local github="$(get_dep_github "$dep")"
    local asset="$(get_dep_asset "$dep")"
    
    if [[ -z "$github" ]]; then
        min_ver="$(get_prog_min_version "$dep")"
        pkg_name="$(get_prog_pkg_name "$dep")"
        github="$(get_prog_github "$dep")"
        asset="$(get_prog_asset "$dep")"
    fi
    
    if [[ "$github" == "build" ]]; then
        if [[ "${HAS_SUDO:-}" != "true" ]]; then
            log_info "No sudo, building $dep from source..."
            install_via_build "$dep"
            return $?
        fi
        if [[ -n "$pkg_name" ]] && install_via_pkg_manager "$pkg_name"; then
            log_success "$dep installed via package manager"
            return 0
        fi
        install_via_build "$dep"
        return $?
    fi
    
    local use_github=false
    
    if [[ -n "$github" ]] && [[ -n "$asset" ]]; then
        if [[ "${HAS_SUDO:-}" != "true" ]]; then
            log_info "No sudo, using GitHub for $dep"
            use_github=true
        fi
    fi
    
    if [[ "$use_github" == "false" ]] && [[ -n "$pkg_name" ]]; then
        local pkg_ver="$(get_pkg_manager_version "$pkg_name")"
        if [[ -n "$min_ver" ]] && [[ -n "$pkg_ver" ]] && ! version_gte "$pkg_ver" "$min_ver"; then
            log_warn "$dep $pkg_ver in package manager is below minimum $min_ver"
            if [[ -n "$github" ]] && [[ -n "$asset" ]]; then
                log_info "Skipping package manager, using GitHub..."
                use_github=true
            fi
        elif install_via_pkg_manager "$pkg_name"; then
            log_success "$dep installed via package manager"
            return 0
        else
            if [[ -n "$github" ]] && [[ -n "$asset" ]]; then
                log_info "Package manager failed, trying GitHub..."
                use_github=true
            fi
        fi
    fi
    
    if [[ "$use_github" == "true" ]] || { [[ -n "$github" ]] && [[ -n "$asset" ]] && [[ -z "$pkg_name" ]]; }; then
        install_via_github "$dep" "$github" "$asset"
        return $?
    fi
    
    if [[ -z "$github" ]] || [[ -z "$asset" ]]; then
        log_error "$dep requires sudo (no GitHub release)"
        return 1
    fi
    
    log_error "Could not install $dep"
    return 1
}

remove_via_pkg_manager() {
    local dep="$1"
    local pkg_name="$(get_dep_pkg_name "$dep")"
    [[ -z "$pkg_name" ]] && pkg_name="$(get_prog_pkg_name "$dep")"
    
    [[ -z "$pkg_name" ]] && return 1
    
    local pm="$(detect_package_manager)"
    case "$pm" in
        apt)
            run_privileged apt-get remove -y "$pkg_name"
            ;;
        pacman)
            run_privileged pacman -Rs --noconfirm "$pkg_name"
            ;;
        brew)
            brew uninstall "$pkg_name"
            ;;
        dnf)
            run_privileged dnf remove -y "$pkg_name"
            ;;
        *)
            return 1
            ;;
    esac
}

remove_dependency() {
    local dep="$1"
    local cmd="$(get_cmd_name "$dep")"
    local install_bin="${BIN_PATH:-$LOCAL_BIN}"
    
    # Check if command exists at all
    if ! command_exists "$cmd"; then
        log_info "$dep not installed"
        return 0
    fi
    
    # Record what exists before removal
    local had_usr_local=false
    local had_install_bin=false
    
    [[ -e "/usr/local/bin/$cmd" ]] || [[ -L "/usr/local/bin/$cmd" ]] && had_usr_local=true
    [[ -e "$install_bin/$cmd" ]] || [[ -L "$install_bin/$cmd" ]] && had_install_bin=true
    
    # Try module-specific remove function first
    if _load_module "$dep"; then
        local func="${dep}_remove"
        if declare -f "$func" &>/dev/null; then
            "$func"
        fi
    fi
    
    # Also try manual removal from managed locations
    if [[ -e "/usr/local/bin/$cmd" ]] || [[ -L "/usr/local/bin/$cmd" ]]; then
        run_privileged rm -f "/usr/local/bin/$cmd"
    fi
    
    if [[ "$install_bin" != "/usr/local/bin" ]]; then
        if [[ -e "$install_bin/$cmd" ]] || [[ -L "$install_bin/$cmd" ]]; then
            rm -f "$install_bin/$cmd"
        fi
    fi
    
    # Check what was actually removed
    local removed_usr_local=false
    local removed_install_bin=false
    
    if [[ "$had_usr_local" == "true" ]]; then
        [[ ! -e "/usr/local/bin/$cmd" ]] && [[ ! -L "/usr/local/bin/$cmd" ]] && removed_usr_local=true
    fi
    
    if [[ "$had_install_bin" == "true" ]] && [[ "$install_bin" != "/usr/local/bin" ]]; then
        [[ ! -e "$install_bin/$cmd" ]] && [[ ! -L "$install_bin/$cmd" ]] && removed_install_bin=true
    fi
    
    # If command no longer exists, we're done
    if ! command_exists "$cmd"; then
        log_success "$dep removed"
        return 0
    fi
    
    # If we removed something from managed locations, success but note it exists elsewhere
    if [[ "$removed_usr_local" == "true" ]] || [[ "$removed_install_bin" == "true" ]]; then
        log_success "$dep removed from managed locations"
        log_info "$cmd still exists at $(command -v "$cmd")"
        return 0
    fi
    
    # Nothing was in managed locations, try package manager
    if [[ "${HAS_SUDO:-}" == "true" ]]; then
        if remove_via_pkg_manager "$dep"; then
            log_success "$dep removed via package manager"
            return 0
        fi
    fi
    
    log_warn "$dep: not installed in managed locations"
    return 1
}
