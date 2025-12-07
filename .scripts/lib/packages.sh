#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

REGISTRY_FILE="$DOTFILES_DIR/.config"

_parse_section() {
    local section="$1"
    local in_section=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" == "[$section]" ]]; then
            in_section=1
            continue
        elif [[ "$line" =~ ^\[.*\]$ ]]; then
            in_section=0
            continue
        fi
        
        if ((in_section)); then
            echo "$line"
        fi
    done < "$REGISTRY_FILE"
}

_get_section_names() {
    local section="$1"
    _parse_section "$section" | cut -d'|' -f1 | while IFS= read -r names; do
        echo "$names" | tr ',' '\n'
    done
}

_get_section_line() {
    local section="$1"
    local name="$2"
    _parse_section "$section" | while IFS= read -r line; do
        local names="${line%%|*}"
        if [[ ",$names," == *",$name,"* ]]; then
            echo "$line"
            return 0
        fi
    done
}

_get_canonical_name() {
    local name="$1"
    local line names canonical
    
    for section in programs dependencies configs; do
        line="$(_get_section_line "$section" "$name")"
        if [[ -n "$line" ]]; then
            names="${line%%|*}"
            canonical="${names%%,*}"
            if [[ "$canonical" == "$name" ]]; then
                echo "$canonical"
                return 0
            fi
        fi
    done
    
    for section in programs dependencies configs; do
        line="$(_get_section_line "$section" "$name")"
        if [[ -n "$line" ]]; then
            echo "${line%%|*}" | cut -d',' -f1
            return 0
        fi
    done
    
    echo "$name"
}

_get_canonical_program_name() {
    local name="$1"
    local line
    
    line="$(_get_section_line "programs" "$name")"
    if [[ -n "$line" ]]; then
        echo "${line%%|*}" | cut -d',' -f1
        return 0
    fi
    
    echo "$name"
}

_get_field() {
    local line="$1"
    local field="$2"
    echo "$line" | cut -d'|' -f"$((field+1))"
}

get_cmd_name() {
    local pkg="$1"
    local canonical="$(_get_canonical_name "$pkg")"
    local line cmd
    
    line="$(_get_section_line "programs" "$canonical")"
    if [[ -n "$line" ]]; then
        cmd="$(_get_field "$line" 1)"
        [[ -n "$cmd" ]] && echo "$cmd" && return
    fi
    
    line="$(_get_section_line "dependencies" "$canonical")"
    if [[ -n "$line" ]]; then
        cmd="$(_get_field "$line" 1)"
        [[ -n "$cmd" ]] && echo "$cmd" && return
    fi
    
    echo "$canonical"
}

get_configs() {
    _get_section_names "configs"
}

get_configs_canonical() {
    _parse_section "configs" | cut -d'|' -f1 | cut -d',' -f1
}

get_config_canonical_name() {
    local config="$1"
    local line
    line="$(_get_section_line "configs" "$config")" || return 1
    echo "${line%%|*}" | cut -d',' -f1
}

get_config_info() {
    local config="$1"
    local line
    line="$(_get_section_line "configs" "$config")" || return 1
    echo "${line#*|}"
}

get_config_path() {
    local config="$1"
    local info path canonical_name
    info="$(get_config_info "$config")" || return 1
    path="${info%%|*}"
    if [[ -z "$path" ]]; then
        canonical_name="$(get_config_canonical_name "$config")"
        echo "$CONFIG_DIR/$canonical_name"
    else
        eval echo "$path"
    fi
}

get_config_deps() {
    local config="$1"
    local info rest
    info="$(get_config_info "$config")" || return 1
    rest="${info#*|}"
    echo "${rest%%|*}" | tr ',' ' '
}

get_config_description() {
    local config="$1"
    local info rest
    info="$(get_config_info "$config")" || return 1
    rest="${info#*|}"
    rest="${rest#*|}"
    echo "$rest"
}

get_programs() {
    _get_section_names "programs"
}

get_programs_canonical() {
    _parse_section "programs" | cut -d'|' -f1 | cut -d',' -f1
}

get_program_info() {
    _get_section_line "programs" "$1"
}

get_prog_field() {
    local prog="$1"
    local field="$2"
    local info
    info="$(get_program_info "$prog")" || return 1
    _get_field "$info" "$field"
}

get_prog_cmd()          { get_prog_field "$1" 1; }
get_prog_min_version()  { get_prog_field "$1" 2; }
get_prog_apt_pkg()      { get_prog_field "$1" 3; }
get_prog_pacman_pkg()   { get_prog_field "$1" 4; }
get_prog_brew_pkg()     { get_prog_field "$1" 5; }
get_prog_dnf_pkg()      { get_prog_field "$1" 6; }
get_prog_github()       { get_prog_field "$1" 7; }
get_prog_asset()        { get_prog_field "$1" 8; }
get_prog_module()       { get_prog_field "$1" 9; }
get_prog_description()  { get_prog_field "$1" 10; }

get_prog_pkg_name() {
    local prog="$1"
    local pm="${2:-$(detect_package_manager)}"
    
    case "$pm" in
        apt)    get_prog_apt_pkg "$prog";;
        pacman) get_prog_pacman_pkg "$prog";;
        brew)   get_prog_brew_pkg "$prog";;
        dnf)    get_prog_dnf_pkg "$prog";;
        *)      echo "$prog";;
    esac
}

get_dependencies() {
    _get_section_names "dependencies"
}

get_dependencies_canonical() {
    _parse_section "dependencies" | cut -d'|' -f1 | cut -d',' -f1
}

get_dependency_info() {
    _get_section_line "dependencies" "$1"
}

get_dep_field() {
    local dep="$1"
    local field="$2"
    local info
    info="$(get_dependency_info "$dep")" || return 1
    _get_field "$info" "$field"
}

get_dep_cmd()          { get_dep_field "$1" 1; }
get_dep_min_version()  { get_dep_field "$1" 2; }
get_dep_apt_pkg()      { get_dep_field "$1" 3; }
get_dep_pacman_pkg()   { get_dep_field "$1" 4; }
get_dep_brew_pkg()     { get_dep_field "$1" 5; }
get_dep_dnf_pkg()      { get_dep_field "$1" 6; }
get_dep_github()       { get_dep_field "$1" 7; }
get_dep_asset()        { get_dep_field "$1" 8; }
get_dep_module()       { get_dep_field "$1" 9; }
get_dep_description()  { get_dep_field "$1" 10; }

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

is_valid_package() {
    local name="$1"
    
    [[ -n "$(_get_section_line "programs" "$name")" ]] && return 0
    [[ -n "$(_get_section_line "dependencies" "$name")" ]] && return 0
    [[ -n "$(_get_section_line "configs" "$name")" ]] && return 0
    return 1
}

is_program() {
    local name="$1"
    [[ -n "$(_get_section_line "programs" "$name")" ]]
}

is_dependency() {
    local name="$1"
    [[ -n "$(_get_section_line "dependencies" "$name")" ]]
}

is_config() {
    local name="$1"
    [[ -n "$(_get_section_line "configs" "$name")" ]]
}

get_all_packages() {
    get_programs
    get_dependencies
}
