#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/install.sh"
source "$SCRIPT_DIR/lib/display.sh"
source "$SCRIPT_DIR/lib/help.sh"

init_system() {  
    local os="$(detect_os)"
    local arch="$(detect_arch)"
    local distro="$(detect_distro)"
    local pkg_manager="$(detect_package_manager)"
    local has_sudo_access="false"
    can_sudo && has_sudo_access="true"
    
    local bin_path="$LOCAL_BIN"
    local share_path="$LOCAL_SHARE"
    [[ "$has_sudo_access" == "true" ]] && bin_path="/usr/local/bin" && share_path="/usr/local/share"
    
    cat > "$SYSTEM_FILE" << EOF
OS=$os
ARCH=$arch
DISTRO=$distro
PKG_MANAGER=$pkg_manager
HAS_SUDO=$has_sudo_access
BIN_PATH=$bin_path
SHARE_PATH=$share_path
HOSTNAME=$(hostname)
USER=$USER
HOME=$HOME
EOF
    
    printf "\n${BOLD}System Info:${NC}\n"
    printf "  OS:              %s\n" "$os"
    printf "  Architecture:    %s\n" "$arch"
    printf "  Distribution:    %s\n" "$distro"
    printf "  Package Manager: %s\n" "$pkg_manager"
    printf "  Sudo Access:     %s\n" "$has_sudo_access"
    printf "  Binary Path:     %s\n" "$bin_path"
    printf "\n"
    log_success "System configuration saved to $SYSTEM_FILE"
}

load_system() {
    [[ -f "$SYSTEM_FILE" ]] && source "$SYSTEM_FILE" || true
}

show_status() {
    load_system
    
    local bin_path="${BIN_PATH:-$LOCAL_BIN}"
    
    printf "\n${BOLD}System:${NC}\n"
    printf "  OS:              %s\n" "${OS:-$(detect_os)}"
    printf "  Architecture:    %s\n" "${ARCH:-$(detect_arch)}"
    printf "  Distribution:    %s\n" "${DISTRO:-$(detect_distro)}"
    printf "  Package Manager: %s\n" "${PKG_MANAGER:-$(detect_package_manager)}"
    printf "  Sudo Access:     %s\n" "${HAS_SUDO:-unknown}"
    printf "  Binary Path:     %s\n" "$bin_path"
    printf "\n"
    
    printf "${BOLD}Configs:\n"
    local configs
    mapfile -t configs < <(get_configs_canonical)
    for cfg in "${configs[@]}"; do
        local canonical="$(get_config_canonical_name "$cfg")"
        local dest="$(get_config_path "$cfg")"
        local src="$DOTFILES_DIR/$canonical"
        local status notes=""
        local dest_display="${dest/#$HOME/\~}"
        
        if [[ -L "$dest" ]]; then
            local target="$(readlink "$dest")"
            if [[ "${target%/}" == "${src%/}" ]]; then
                status="${GREEN}✓${NC} linked"
            else
                status="${YELLOW}→${NC} other"
                notes=" -> $target"
            fi
        elif [[ -e "$dest" ]]; then
            status="${YELLOW}!${NC} exists"
            notes=" (not a symlink)"
        else
            status="${RED}✗${NC} missing"
        fi
        
        printf "  %-10s %b ${DIM}(%s)${NC}%s\n" "$cfg" "$status" "$dest_display" "$notes"
    done
    printf "\n"
    
    _display_packages "Programs" "$(get_programs_canonical)"
    _display_packages "Dependencies" "$(get_dependencies_canonical)"
}

_display_packages() {
    local title="$1"
    shift
    local packages=("$@")
    
    printf "${BOLD}%s:\n" "$title"
    for pkg in $packages; do
        local cmd="$(get_cmd_name "$pkg")"
        local bin_path="${BIN_PATH:-$LOCAL_BIN}"
        local status_icon ver="" pkg_status loc=""
        
        check_dependency "$pkg" && pkg_status=0 || pkg_status=$?
        
        if [[ -f "$bin_path/$cmd" ]]; then
            loc="${bin_path/#$HOME/\~}"
        elif [[ -f "/usr/local/bin/$cmd" ]]; then
            loc="/usr/local/bin"
        elif command_exists "$cmd"; then
            loc="system"
        fi
        
        case $pkg_status in
            0) 
                status_icon="${GREEN}✓${NC}"
                ver="$(get_installed_version "$cmd" "$pkg")"
                ;;
            1) status_icon="${RED}✗${NC}";;
            2) 
                status_icon="${YELLOW}↓${NC}"
                local min_ver="$(get_dep_min_version "$pkg")"
                [[ -z "$min_ver" ]] && min_ver="$(get_prog_min_version "$pkg")"
                ver="$(get_installed_version "$cmd" "$pkg") < $min_ver"
                ;;
        esac
        
        if [[ -n "$loc" ]]; then
            printf "  %-10s %b %s ${DIM}(%s)${NC}\n" "$pkg" "$status_icon" "$ver" "$loc"
        else
            printf "  %-10s %b %s\n" "$pkg" "$status_icon" "$ver"
        fi
    done
    printf "\n"
}

link_config() {
    local config="$1"
    local canonical="$(get_config_canonical_name "$config")"
    local src="$DOTFILES_DIR/$canonical"
    local dest="$(get_config_path "$config")"
    
    if [[ ! -d "$src" ]]; then
        log_error "Config source not found: $src"
        return 1
    fi
    
    if [[ -L "$dest" ]]; then
        local target="$(readlink "$dest")"
        if [[ "${target%/}" == "${src%/}" ]]; then
            log_info "$config: already linked"
            [[ "$config" == "zsh" ]] && setup_shell || true
            return 0
        else
            log_warn "$config: symlink exists but points to $target"
            return 1
        fi
    fi
    
    if [[ -e "$dest" ]]; then
        log_warn "$config: $dest exists (not a symlink)"
        log_info "Please backup or remove it first"
        return 1
    fi
    
    ensure_dir "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log_success "$config: linked -> $dest"
    
    [[ "$config" == "zsh" ]] && setup_shell || true
    return 0
}

unlink_config() {
    local config="$1"
    local canonical="$(get_config_canonical_name "$config")"
    local src="$DOTFILES_DIR/$canonical"
    local dest="$(get_config_path "$config")"
    
    if [[ ! -L "$dest" ]]; then
        log_info "$config: not a symlink, nothing to remove"
        return 0
    fi
    
    local target="$(readlink "$dest")"
    if [[ "${target%/}" != "${src%/}" ]]; then
        log_warn "$config: symlink points to $target, not removing"
        return 1
    fi
    
    rm "$dest"
    log_success "$config: unlinked"
}

do_link() {
    local items=("$@")
    local configs
    mapfile -t configs < <(get_configs_canonical)
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_configs_display)
        show_selection_menu "Select configs to link" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#configs[@]}")"
        [[ "$indices" == "EXIT" ]] && { log_info "Cancelled"; return 0; }
        
        for idx in $indices; do
            items+=("${configs[$idx]}")
        done
    fi
    
    [[ ${#items[@]} -eq 0 ]] && { log_warn "Nothing selected"; return 0; }
    
    log_step "Linking configs"
    for cfg in "${items[@]}"; do
        link_config "$cfg" || log_warn "Failed to link $cfg"
    done
}

do_unlink() {
    local items=("$@")
    local configs
    mapfile -t configs < <(get_configs_canonical)
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_configs_display)
        show_selection_menu "Select configs to unlink" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#configs[@]}")"
        [[ "$indices" == "EXIT" ]] && { log_info "Cancelled"; return 0; }
        
        for idx in $indices; do
            items+=("${configs[$idx]}")
        done
    fi
    
    [[ ${#items[@]} -eq 0 ]] && { log_warn "Nothing selected"; return 0; }
    
    log_step "Unlinking configs"
    for cfg in "${items[@]}"; do
        unlink_config "$cfg"
    done
}

do_install() {
    local items=("$@")
    local programs
    mapfile -t programs < <(get_programs_canonical)
    
    local normalized=()
    for item in "${items[@]}"; do
        normalized+=("$(_get_canonical_name "$item")")
    done
    items=("${normalized[@]}")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_programs_display)
        show_selection_menu "Select programs to install" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#programs[@]}")"
        [[ "$indices" == "EXIT" ]] && { log_info "Cancelled"; return 0; }
        
        for idx in $indices; do
            items+=("${programs[$idx]}")
        done
    fi
    
    [[ ${#items[@]} -eq 0 ]] && { log_warn "Nothing selected"; return 0; }
    
    local configs deps_to_install=()
    mapfile -t configs < <(get_configs_canonical)
    
    for prog in "${items[@]}"; do
        local prog_canonical="$(_get_canonical_program_name "$prog")"
        for cfg in "${configs[@]}"; do
            local config_deps="$(get_config_deps "$cfg")"
            for dep in $config_deps; do
                local dep_canonical="$(_get_canonical_program_name "$dep")"
                if [[ "$dep_canonical" == "$prog_canonical" ]]; then
                    for d in $config_deps; do
                        if ! is_program "$d" && ! _array_contains "$d" "${deps_to_install[@]}"; then
                            deps_to_install+=("$d")
                        fi
                    done
                    break
                fi
            done
        done
    done
    
    local selected_deps=()
    if [[ ${#deps_to_install[@]} -gt 0 ]]; then
        local menu_items=()
        for dep in "${deps_to_install[@]}"; do
            local desc="$(get_dep_description "$dep")"
            local cmd="$(get_cmd_name "$dep")"
            local status_icon dep_status
            check_dependency "$dep" && dep_status=0 || dep_status=$?
            case $dep_status in
                0) status_icon="${GREEN}✓${NC}";;
                1) status_icon="${RED}✗${NC}";;
                2) status_icon="${YELLOW}↓${NC}";;
            esac
            menu_items+=("$(printf "%b %s - %s" "$status_icon" "$dep" "$desc")")
        done
        
        show_selection_menu "Select dependencies to install" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#deps_to_install[@]}")"
        
        if [[ "$indices" != "EXIT" ]]; then
            for idx in $indices; do
                selected_deps+=("${deps_to_install[$idx]}")
            done
        fi
    fi
    
    printf "\n${BOLD}Summary:${NC}\n" >&2
    [[ ${#items[@]} -gt 0 ]] && printf "  ${GREEN}Install programs:${NC} %s\n" "${items[*]}" >&2
    [[ ${#selected_deps[@]} -gt 0 ]] && printf "  ${GREEN}Install deps:${NC}     %s\n" "${selected_deps[*]}" >&2
    printf "\n" >&2
    
    if ! ask_yes_no "Proceed?"; then
        return 0
    fi
    
    if [[ ${#items[@]} -gt 0 ]]; then
        log_step "Installing programs"
        for prog in "${items[@]}"; do
            install_dependency "$prog" || log_warn "Failed to install $prog"
        done
    fi
    
    if [[ ${#selected_deps[@]} -gt 0 ]]; then
        log_step "Installing dependencies"
        for dep in "${selected_deps[@]}"; do
            install_dependency "$dep" || log_warn "Failed to install $dep"
        done
    fi
    
    log_success "Installation complete"
}

do_remove() {
    local items=("$@")
    local programs
    mapfile -t programs < <(get_programs_canonical)
    
    local normalized=()
    for item in "${items[@]}"; do
        normalized+=("$(_get_canonical_name "$item")")
    done
    items=("${normalized[@]}")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_programs_display)
        show_selection_menu "Select programs to remove" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#programs[@]}")"
        [[ "$indices" == "EXIT" ]] && { log_info "Cancelled"; return 0; }
        
        for idx in $indices; do
            items+=("${programs[$idx]}")
        done
    fi
    
    [[ ${#items[@]} -eq 0 ]] && { log_warn "Nothing selected"; return 0; }
    
    local configs
    mapfile -t configs < <(get_configs_canonical)
    local deps_to_remove=()
    
    for prog in "${items[@]}"; do
        local prog_canonical="$(_get_canonical_program_name "$prog")"
        for cfg in "${configs[@]}"; do
            local config_deps="$(get_config_deps "$cfg")"
            for dep in $config_deps; do
                local dep_canonical="$(_get_canonical_program_name "$dep")"
                if [[ "$dep_canonical" == "$prog_canonical" ]]; then
                    for d in $config_deps; do
                        if ! is_program "$d" && ! _array_contains "$d" "${deps_to_remove[@]}"; then
                            deps_to_remove+=("$d")
                        fi
                    done
                    break
                fi
            done
        done
    done
    
    local selected_deps=()
    if [[ ${#deps_to_remove[@]} -gt 0 ]]; then
        local menu_items=()
        for dep in "${deps_to_remove[@]}"; do
            local desc="$(get_dep_description "$dep")"
            local cmd="$(get_cmd_name "$dep")"
            local status_icon dep_status
            check_dependency "$dep" && dep_status=0 || dep_status=$?
            case $dep_status in
                0) status_icon="${GREEN}✓${NC}";;
                1) status_icon="${RED}✗${NC}";;
                2) status_icon="${YELLOW}↓${NC}";;
            esac
            menu_items+=("$(printf "%b %s - %s" "$status_icon" "$dep" "$desc")")
        done
        
        show_selection_menu "Select dependencies to remove" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#deps_to_remove[@]}")"
        
        if [[ "$indices" != "EXIT" ]]; then
            for idx in $indices; do
                selected_deps+=("${deps_to_remove[$idx]}")
            done
        fi
    fi
    
    printf "\n${BOLD}Summary:${NC}\n" >&2
    [[ ${#items[@]} -gt 0 ]] && printf "  ${RED}Remove programs:${NC} %s\n" "${items[*]}" >&2
    [[ ${#selected_deps[@]} -gt 0 ]] && printf "  ${RED}Remove deps:${NC}     %s\n" "${selected_deps[*]}" >&2
    printf "\n" >&2
    
    if ! ask_yes_no "Proceed?"; then
        return 0
    fi
    
    log_step "Removing programs"
    for prog in "${items[@]}"; do
        remove_dependency "$prog" || log_warn "Failed to remove $prog"
    done
    
    if [[ ${#selected_deps[@]} -gt 0 ]]; then
        log_step "Removing dependencies"
        for dep in "${selected_deps[@]}"; do
            remove_dependency "$dep" || log_warn "Failed to remove $dep"
        done
    fi

    log_success "Removal complete"
}

do_deps() {
    local items=("$@")
    local deps
    mapfile -t deps < <(get_dependencies_canonical)
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_dependencies_display)
        show_selection_menu "Select dependencies to install" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#deps[@]}")"
        [[ "$indices" == "EXIT" ]] && { log_info "Cancelled"; return 0; }
        
        for idx in $indices; do
            items+=("${deps[$idx]}")
        done
    fi
    
    [[ ${#items[@]} -eq 0 ]] && { log_warn "Nothing selected"; return 0; }
    
    log_step "Installing dependencies"
    for dep in "${items[@]}"; do
        install_dependency "$dep" || log_warn "Failed to install $dep"
    done
}

do_remove_deps() {
    local items=("$@")
    local deps
    mapfile -t deps < <(get_dependencies_canonical)
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_dependencies_display)
        show_selection_menu "Select dependencies to remove" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#deps[@]}")"
        [[ "$indices" == "EXIT" ]] && { log_info "Cancelled"; return 0; }
        
        for idx in $indices; do
            items+=("${deps[$idx]}")
        done
    fi
    
    [[ ${#items[@]} -eq 0 ]] && { log_warn "Nothing selected"; return 0; }
    
    printf "\n${BOLD}Summary:${NC}\n" >&2
    printf "  ${RED}Remove:${NC} %s\n" "${items[*]}" >&2
    printf "\n" >&2
    
    if ! ask_yes_no "Proceed?"; then
        return 0
    fi
    
    log_step "Removing dependencies"
    for dep in "${items[@]}"; do
        remove_dependency "$dep"
    done

    log_success "Removal complete"
}

_array_contains() {
    local needle="$1"
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

do_pull() {
    local items=("$@")
    local configs
    mapfile -t configs < <(get_configs_canonical)
    
    log_step "Updating submodules"
    cd "$DOTFILES_DIR"
    
    if [[ ${#items[@]} -eq 0 ]]; then
        local menu_items=()
        mapfile -t menu_items < <(get_configs_display)
        show_selection_menu "Select configs to update" "${menu_items[@]}" >&2
        
        local input
        read -r input
        local indices="$(parse_selection "$input" "${#configs[@]}")"
        
        if [[ "$indices" != "EXIT" ]]; then
            for idx in $indices; do
                items+=("${configs[$idx]}")
            done
        fi
    fi
    
    if [[ ${#items[@]} -eq 0 ]]; then
        git submodule update --init --recursive
    else
        local paths=()
        while IFS= read -r path; do
            for config in "${items[@]}"; do
                if [[ "$path" == "$config" || "$path" == "$config/"* ]]; then
                    paths+=("$path")
                fi
            done
        done < <(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
        
        if [[ ${#paths[@]} -gt 0 ]]; then
            git submodule update --init --recursive -- "${paths[@]}"
        else
            log_info "No submodules found for selected configs"
        fi
    fi
    
    log_success "Submodules updated"
}

setup_shell() {
    local zsh_path=""
    local bin_path="${BIN_PATH:-$LOCAL_BIN}"
    
    if [[ -x "$bin_path/zsh" ]]; then
        zsh_path="$bin_path/zsh"
    elif command_exists zsh; then
        zsh_path="$(command -v zsh)"
    else
        return 1
    fi
    
    local profile_file="$HOME/.profile"
    [[ -f "$HOME/.bash_profile" ]] && profile_file="$HOME/.bash_profile"
    
    if grep -q "exec.*zsh" "$profile_file" 2>/dev/null; then
        return 0
    fi
    
    [[ ! -f "$profile_file" ]] && touch "$profile_file"
    
    cat >> "$profile_file" << EOF

if [ -n "\$PS1" ] && [ -n "\$BASH_VERSION" ]; then
    if [ -x "$zsh_path" ]; then
        export SHELL="$zsh_path"
        exec "$zsh_path" -l
    fi
fi
EOF
    log_success "Added zsh exec to $profile_file"
}

main() {
    local cmd="${1:-}"
    shift || true
    
    load_system
    
    case "$cmd" in
        init)        init_system;;
        status)      show_status;;
        install)     do_install "$@";;
        remove)      do_remove "$@";;
        link)        do_link "$@";;
        unlink)      do_unlink "$@";;
        deps)        do_deps "$@";;
        remove-deps) do_remove_deps "$@";;
        pull)        do_pull "$@";;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
