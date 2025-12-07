#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

parse_selection() {
    local input="$1"
    local max="$2"
    local result=()
    
    if [[ "$input" =~ ^[qQ0]$|^(exit|quit|none)$ ]]; then
        echo "EXIT"
        return 0
    fi
    
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

show_selection_menu() {
    local title="$1"
    shift
    local sections=("$@")
    
    printf "\n${BOLD}${CYAN}%s${NC}\n" "$title"
    printf "${DIM}────────────────────────────────────────${NC}\n\n"
    
    local i=1
    local section_name=""
    for entry in "${sections[@]}"; do
        if [[ "$entry" == "---"* ]]; then
            section_name="${entry#---}"
            printf "${BOLD}%s${NC}\n" "$section_name"
        else
            printf "  ${BOLD}%2d${NC}) %b\n" "$i" "$entry"
            ((i++)) || true
        fi
    done
    
    printf "\n${BOLD}Enter selection${NC} ${DIM}(1 2 3, 1-3, all, q=quit)${NC} [default=all]: "
}
