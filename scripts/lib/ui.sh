#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

display_selection_list() {
    local header="$1"
    shift
    local items=("$@")
    
    printf "\n${BOLD}${CYAN}%s${NC}\n" "$header"
    printf "${DIM}────────────────────────────────────────${NC}\n"
    
    local i=1
    for item in "${items[@]}"; do
        printf "  ${BOLD}%2d${NC}) %s\n" "$i" "$item"
        ((i++)) || true
    done
    
    printf "\n"
}

parse_selection() {
    local input="$1"
    local max="$2"
    local result=()
    
    if [[ -z "$input" || "$input" == "all" ]]; then
        for ((i=0; i<max; i++)); do
            result+=("$i")
        done
        echo "${result[*]}"
        return 0
    fi
    
    input="${input//,/ }"
    
    for token in $input; do
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            for ((i=start; i<=end; i++)); do
                if ((i >= 1 && i <= max)); then
                    result+=("$((i-1))")
                fi
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            if ((token >= 1 && token <= max)); then
                result+=("$((token-1))")
            fi
        fi
    done
    
    printf '%s\n' "${result[@]}" | sort -nu | tr '\n' ' '
}

interactive_select() {
    local prompt="$1"
    shift
    local items=("$@")
    local count=${#items[@]}
    
    if ((count == 0)); then
        return 0
    fi
    
    display_selection_list "$prompt" "${items[@]}"
    
    printf "${BOLD}Enter selection${NC} ${DIM}(e.g., 1 2 3, 1-3, all)${NC} [default=all]: "
    
    local input
    read -r input
    
    local indices
    indices="$(parse_selection "$input" "$count")"
    
    local selected=()
    for idx in $indices; do
        selected+=("${items[$idx]%%|*}")
    done
    
    printf '%s\n' "${selected[@]}"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    
    if ! is_interactive; then
        [[ "$default" == "y" ]]
        return
    fi
    
    local suffix
    if [[ "$default" == "y" ]]; then
        suffix="[Y/n]"
    else
        suffix="[y/N]"
    fi
    
    printf "${BOLD}%s${NC} %s " "$prompt" "$suffix"
    
    local answer
    read -r answer
    
    if [[ -z "$answer" ]]; then
        [[ "$default" == "y" ]]
    else
        [[ "$answer" =~ ^[Yy] ]]
    fi
}

show_progress() {
    local msg="$1"
    shift
    
    printf "${CYAN}::${NC} %s... " "$msg"
    
    if "$@" >/dev/null 2>&1; then
        printf "${GREEN}done${NC}\n"
        return 0
    else
        printf "${RED}failed${NC}\n"
        return 1
    fi
}
