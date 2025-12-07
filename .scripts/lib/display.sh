#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
[[ -z "${REGISTRY_FILE:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/packages.sh"
[[ -z "$(declare -f get_installed_version)" ]] && source "$(dirname "${BASH_SOURCE[0]}")/install.sh"

get_install_location() {
    local cmd="$1"
    local bin_path="${BIN_PATH:-$LOCAL_BIN}"
    
    if [[ -f "$bin_path/$cmd" ]]; then
        echo "${bin_path/#$HOME/\~}"
    elif [[ -f "$LOCAL_BIN/$cmd" ]]; then
        echo "~/.local/bin"
    elif [[ -f "/usr/local/bin/$cmd" ]]; then
        echo "/usr/local/bin"
    elif command_exists "$cmd"; then
        echo "system"
    fi
}

get_configs_display() {
    local configs
    mapfile -t configs < <(get_configs_canonical)
    
    for cfg in "${configs[@]}"; do
        local desc="$(get_config_description "$cfg")"
        local dest="$(get_config_path "$cfg")"
        local status_icon
        
        if [[ -L "$dest" ]]; then
            status_icon="${GREEN}✓${NC}"
        elif [[ -e "$dest" ]]; then
            status_icon="${YELLOW}!${NC}"
        else
            status_icon="${RED}✗${NC}"
        fi
        
        local dest_display="${dest/#$HOME/\~}"
        printf "%b %s - %s ${DIM}(%s)${NC}\n" "$status_icon" "$cfg" "$desc" "$dest_display"
    done
}

get_dependencies_display() {
    local deps
    mapfile -t deps < <(get_dependencies_canonical)
    
    for dep in "${deps[@]}"; do
        local desc="$(get_dep_description "$dep")"
        local cmd="$(get_cmd_name "$dep")"
        local status_icon dep_status
        
        check_dependency "$dep" && dep_status=0 || dep_status=$?
        
        local loc="$(get_install_location "$cmd")"
        
        case $dep_status in
            0) status_icon="${GREEN}✓${NC}";;
            1) status_icon="${RED}✗${NC}";;
            2) status_icon="${YELLOW}↓${NC}";;
        esac
        
        if [[ -n "$loc" ]]; then
            printf "%b %s - %s ${DIM}(%s)${NC}\n" "$status_icon" "$dep" "$desc" "$loc"
        else
            printf "%b %s - %s\n" "$status_icon" "$dep" "$desc"
        fi
    done
}

get_programs_display() {
    local programs
    mapfile -t programs < <(get_programs_canonical)
    
    for prog in "${programs[@]}"; do
        local desc="$(get_prog_description "$prog")"
        local cmd="$(get_cmd_name "$prog")"
        local status_icon prog_status
        
        check_dependency "$prog" && prog_status=0 || prog_status=$?
        
        local loc="$(get_install_location "$cmd")"
        
        case $prog_status in
            0) status_icon="${GREEN}✓${NC}";;
            1) status_icon="${RED}✗${NC}";;
            2) status_icon="${YELLOW}↓${NC}";;
        esac
        
        if [[ -n "$loc" ]]; then
            printf "%b %s - %s ${DIM}(%s)${NC}\n" "$status_icon" "$prog" "$desc" "$loc"
        else
            printf "%b %s - %s\n" "$status_icon" "$prog" "$desc"
        fi
    done
}
