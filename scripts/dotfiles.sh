#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/packages.sh"

init_system() {
    log_step "Initializing system configuration"
    
    local os="$(detect_os)"
    local arch="$(detect_arch)"
    local distro="$(detect_distro)"
    local pkg_manager="$(detect_package_manager)"
    
    cat > "$SYSTEM_FILE" << EOF
OS=$os
ARCH=$arch
DISTRO=$distro
PKG_MANAGER=$pkg_manager
HOSTNAME=$(hostname)
USER=$USER
HOME=$HOME
EOF
    
    log_success "System configuration saved to $SYSTEM_FILE"
    
    printf "\n${BOLD}System Info:${NC}\n"
    printf "  OS:              %s\n" "$os"
    printf "  Architecture:    %s\n" "$arch"
    printf "  Distribution:    %s\n" "$distro"
    printf "  Package Manager: %s\n" "$pkg_manager"
    printf "  Hostname:        %s\n" "$(hostname)"
    printf "\n"
}

load_system() {
    if [[ -f "$SYSTEM_FILE" ]]; then
        source "$SYSTEM_FILE"
    fi
}

show_status() {
    printf "\n${BOLD}${CYAN}Dotfiles Status${NC}\n\n"
    
    printf "${BOLD}System:${NC}\n"
    printf "  OS:       %s\n" "$(detect_os)"
    printf "  Arch:     %s\n" "$(detect_arch)"
    printf "  Distro:   %s\n" "$(detect_distro)"
    printf "  PkgMgr:   %s\n" "$(detect_package_manager)"
    printf "\n"
    
    printf "${BOLD}Configs:${NC} ${DIM}(✓ linked, ! exists, ✗ missing)${NC}\n"
    local configs
    mapfile -t configs < <(get_configs)
    for cfg in "${configs[@]}"; do
        local dest="$CONFIG_DIR/$cfg"
        local src="$DOTFILES_DIR/$cfg"
        local status notes=""
        
        if [[ -L "$dest" ]]; then
            local target="$(readlink "$dest")"
            if [[ "${target%/}" == "${src%/}" ]]; then
                status="${GREEN}✓${NC} linked"
            else
                status="${YELLOW}→${NC} other"
                notes="-> $target"
            fi
        elif [[ -e "$dest" ]]; then
            status="${YELLOW}!${NC} exists"
            notes="not a symlink"
        else
            status="${RED}✗${NC} missing"
        fi
        
        printf "  %-10s %b %s\n" "$cfg" "$status" "$notes"
    done
    printf "\n"
    
    printf "${BOLD}Dependencies:${NC} ${DIM}(✓ ok, ↓ outdated, ✗ missing)${NC}\n"
    local deps
    mapfile -t deps < <(get_dependencies)
    for dep in "${deps[@]}"; do
        local cmd="$dep"
        case "$dep" in
            neovim) cmd="nvim";;
            ripgrep) cmd="rg";;
        esac
        
        local status_icon ver="" dep_status
        check_dependency "$dep" "$cmd" && dep_status=0 || dep_status=$?
        case $dep_status in
            0) 
                status_icon="${GREEN}✓${NC}"
                ver="$(get_installed_version "$cmd")"
                ;;
            1) status_icon="${RED}✗${NC}";;
            2) 
                status_icon="${YELLOW}↓${NC}"
                ver="$(get_installed_version "$cmd") < $(get_dep_min_version "$dep")"
                ;;
        esac
        
        printf "  %-10s %b %s\n" "$dep" "$status_icon" "$ver"
    done
    printf "\n"
}

link_config() {
    local config="$1"
    local src="$DOTFILES_DIR/$config"
    local dest="$CONFIG_DIR/$config"
    
    if [[ ! -d "$src" ]]; then
        log_error "Config source not found: $src"
        return 1
    fi
    
    if [[ -L "$dest" ]]; then
        local target="$(readlink "$dest")"
        if [[ "${target%/}" == "${src%/}" ]]; then
            log_info "$config: already linked"
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
    
    ensure_dir "$CONFIG_DIR"
    ln -s "$src" "$dest"
    log_success "$config: linked -> $dest"
}

unlink_config() {
    local config="$1"
    local src="$DOTFILES_DIR/$config"
    local dest="$CONFIG_DIR/$config"
    
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

do_install() {
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "\n${BOLD}${CYAN}Select items to install:${NC}\n"
        printf "${DIM}────────────────────────────────────────${NC}\n\n"
        
        printf "${BOLD}Configs:${NC}\n"
        local configs_display
        mapfile -t configs_display < <(get_configs_display)
        local i=1
        for item in "${configs_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Dependencies:${NC}\n"
        local deps_display
        mapfile -t deps_display < <(get_dependencies_display)
        for item in "${deps_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
        local input
        read -r input
        
        local configs deps
        mapfile -t configs < <(get_configs)
        mapfile -t deps < <(get_dependencies)
        local all_items=("${configs[@]}" "${deps[@]}")
        local total=${#all_items[@]}
        
        local indices
        indices="$(parse_selection "$input" "$total")"
        
        for idx in $indices; do
            items+=("${all_items[$idx]}")
        done
    fi
    
    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "Nothing selected"
        return 0
    fi
    
    local configs_to_install=()
    local deps_to_install=()
    local all_configs all_deps
    mapfile -t all_configs < <(get_configs)
    mapfile -t all_deps < <(get_dependencies)
    
    for item in "${items[@]}"; do
        if printf '%s\n' "${all_configs[@]}" | grep -qx "$item"; then
            configs_to_install+=("$item")
            local config_deps
            config_deps="$(get_config_deps "$item")"
            for dep in $config_deps; do
                if ! printf '%s\n' "${deps_to_install[@]}" | grep -qx "$dep"; then
                    deps_to_install+=("$dep")
                fi
            done
        elif printf '%s\n' "${all_deps[@]}" | grep -qx "$item"; then
            if ! printf '%s\n' "${deps_to_install[@]}" | grep -qx "$item"; then
                deps_to_install+=("$item")
            fi
        fi
    done
    
    printf "\n${BOLD}Will install:${NC}\n"
    [[ ${#deps_to_install[@]} -gt 0 ]] && printf "  Dependencies: %s\n" "${deps_to_install[*]}"
    [[ ${#configs_to_install[@]} -gt 0 ]] && printf "  Configs: %s\n" "${configs_to_install[*]}"
    printf "\n"
    
    if ! ask_yes_no "Proceed?"; then
        return 0
    fi
    
    if [[ ${#deps_to_install[@]} -gt 0 ]]; then
        log_step "Installing dependencies"
        for dep in "${deps_to_install[@]}"; do
            install_dependency "$dep" || log_warn "Failed to install $dep"
        done
    fi
    
    if [[ ${#configs_to_install[@]} -gt 0 ]]; then
        log_step "Linking configs"
        for cfg in "${configs_to_install[@]}"; do
            link_config "$cfg" || log_warn "Failed to link $cfg"
        done
    fi
    
    log_success "Installation complete"
}

do_uninstall() {
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "\n${BOLD}${CYAN}Select items to uninstall:${NC}\n"
        printf "${DIM}────────────────────────────────────────${NC}\n\n"
        
        printf "${BOLD}Configs:${NC}\n"
        local configs_display
        mapfile -t configs_display < <(get_configs_display)
        local i=1
        for item in "${configs_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Dependencies:${NC}\n"
        local deps_display
        mapfile -t deps_display < <(get_dependencies_display)
        for item in "${deps_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
        local input
        read -r input
        
        local configs deps
        mapfile -t configs < <(get_configs)
        mapfile -t deps < <(get_dependencies)
        local all_items=("${configs[@]}" "${deps[@]}")
        local total=${#all_items[@]}
        
        local indices
        indices="$(parse_selection "$input" "$total")"
        
        for idx in $indices; do
            items+=("${all_items[$idx]}")
        done
    fi
    
    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "Nothing selected"
        return 0
    fi
    
    local configs_to_remove=()
    local deps_to_remove=()
    local all_configs all_deps
    mapfile -t all_configs < <(get_configs)
    mapfile -t all_deps < <(get_dependencies)
    
    for item in "${items[@]}"; do
        if printf '%s\n' "${all_configs[@]}" | grep -qx "$item"; then
            configs_to_remove+=("$item")
        elif printf '%s\n' "${all_deps[@]}" | grep -qx "$item"; then
            deps_to_remove+=("$item")
        fi
    done
    
    printf "\n${BOLD}Will uninstall:${NC}\n"
    [[ ${#configs_to_remove[@]} -gt 0 ]] && printf "  Configs: %s\n" "${configs_to_remove[*]}"
    [[ ${#deps_to_remove[@]} -gt 0 ]] && printf "  Dependencies: %s\n" "${deps_to_remove[*]}"
    printf "\n"
    
    if ! ask_yes_no "Proceed?" "n"; then
        return 0
    fi
    
    if [[ ${#configs_to_remove[@]} -gt 0 ]]; then
        log_step "Unlinking configs"
        for cfg in "${configs_to_remove[@]}"; do
            unlink_config "$cfg"
        done
    fi
    
    if [[ ${#deps_to_remove[@]} -gt 0 ]]; then
        log_step "Removing dependencies (GitHub installs only)"
        for dep in "${deps_to_remove[@]}"; do
            if [[ -f "$LOCAL_BIN/$dep" ]] || [[ "$dep" == "neovim" && -f "$LOCAL_BIN/nvim" ]]; then
                uninstall_github_dep "$dep"
            else
                log_info "$dep: installed via package manager, use your package manager to remove"
            fi
        done
    fi
    
    log_success "Uninstall complete"
}

do_link() {
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "\n${BOLD}${CYAN}Select configs to link:${NC}\n"
        printf "${DIM}────────────────────────────────────────${NC}\n\n"
        
        local configs_display
        mapfile -t configs_display < <(get_configs_display)
        local i=1
        for item in "${configs_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
        local input
        read -r input
        
        local configs
        mapfile -t configs < <(get_configs)
        local total=${#configs[@]}
        
        local indices
        indices="$(parse_selection "$input" "$total")"
        
        for idx in $indices; do
            items+=("${configs[$idx]}")
        done
    fi
    
    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "Nothing selected"
        return 0
    fi
    
    log_step "Linking configs"
    for cfg in "${items[@]}"; do
        link_config "$cfg" || log_warn "Failed to link $cfg"
    done
}

do_unlink() {
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "\n${BOLD}${CYAN}Select configs to unlink:${NC}\n"
        printf "${DIM}────────────────────────────────────────${NC}\n\n"
        
        local configs_display
        mapfile -t configs_display < <(get_configs_display)
        local i=1
        for item in "${configs_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
        local input
        read -r input
        
        local configs
        mapfile -t configs < <(get_configs)
        local total=${#configs[@]}
        
        local indices
        indices="$(parse_selection "$input" "$total")"
        
        for idx in $indices; do
            items+=("${configs[$idx]}")
        done
    fi
    
    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "Nothing selected"
        return 0
    fi
    
    log_step "Unlinking configs"
    for cfg in "${items[@]}"; do
        unlink_config "$cfg"
    done
}

do_deps() {
    local items=("$@")
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "\n${BOLD}${CYAN}Select dependencies to install:${NC}\n"
        printf "${DIM}────────────────────────────────────────${NC}\n\n"
        
        local deps_display
        mapfile -t deps_display < <(get_dependencies_display)
        local i=1
        for item in "${deps_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
        local input
        read -r input
        
        local deps
        mapfile -t deps < <(get_dependencies)
        local total=${#deps[@]}
        
        local indices
        indices="$(parse_selection "$input" "$total")"
        
        for idx in $indices; do
            items+=("${deps[$idx]}")
        done
    fi
    
    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "Nothing selected"
        return 0
    fi
    
    log_step "Installing dependencies"
    for dep in "${items[@]}"; do
        install_dependency "$dep" || log_warn "Failed to install $dep"
    done
}

do_pull() {
    local items=("$@")
    
    log_step "Updating submodules"
    cd "$DOTFILES_DIR"
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "\n${BOLD}${CYAN}Select configs to update submodules:${NC}\n"
        printf "${DIM}────────────────────────────────────────${NC}\n\n"
        
        local configs_display
        mapfile -t configs_display < <(get_configs_display)
        local i=1
        for item in "${configs_display[@]}"; do
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$item"
            ((i++)) || true
        done
        
        printf "\n${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
        local input
        read -r input
        
        local configs
        mapfile -t configs < <(get_configs)
        local total=${#configs[@]}
        
        local indices
        indices="$(parse_selection "$input" "$total")"
        
        for idx in $indices; do
            items+=("${configs[$idx]}")
        done
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

show_help() {
    cat << 'EOF'

Dotfiles Manager

Usage: dotfiles.sh <command> [args...]

Commands:
    init              Initialize system configuration file
    status            Show status of configs and dependencies
    install [items]   Install configs and dependencies
    uninstall [items] Remove configs and dependencies  
    link [configs]    Create symlinks for configs
    unlink [configs]  Remove symlinks for configs
    deps [deps]       Install dependencies only
    pull [configs]    Update git submodules
    help              Show this help message

Selection: 1, 1-3, 1 2 5, or Enter for all

EOF
}

main() {
    local cmd="${1:-}"
    shift || true
    
    case "$cmd" in
        init)
            init_system
            ;;
        status)
            show_status
            ;;
        install)
            do_install "$@"
            ;;
        uninstall)
            do_uninstall "$@"
            ;;
        link)
            do_link "$@"
            ;;
        unlink)
            do_unlink "$@"
            ;;
        deps)
            do_deps "$@"
            ;;
        pull)
            do_pull "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
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
