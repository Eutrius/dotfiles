#!/usr/bin/env bash

[[ -z "${DOTFILES_DIR:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
[[ -z "${REGISTRY_FILE:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/packages.sh"

show_help() {
    local programs="$(get_programs | tr '\n' ' ')"
    local dependencies="$(get_dependencies | tr '\n' ' ')"
    local configs="$(get_configs | tr '\n' ' ')"

    printf "${BOLD}Usage:${NC} make <target> [args...]\n\n"
    
    printf "  make init                Initialize system configuration\n"
    printf "  make status              Show status of all configs and packages\n"
    printf "  make link [config...]    Link configs (all if none specified)\n"
    printf "  make unlink [config...]  Unlink configs (interactive if none specified)\n"
    printf "  make install [prog...]   Install programs (all if none specified)\n"
    printf "  make remove [prog...]    Remove programs (interactive if none specified)\n"
    printf "  make deps [dep...]       Install dependencies (all if none specified)\n"
    printf "  make remove-deps [dep...]  Remove dependencies (interactive if none specified)\n"
    printf "  make pull [config...]    Update git submodules (all if none specified)\n"
    printf "  make clean               Remove generated files\n"
    printf "  make help                Show this help\n"
    printf "\n"
    
    printf "${BOLD}Valid Configs:${NC}      %s\n" "$configs"
    printf "${BOLD}Valid Programs:${NC}     %s\n" "$programs"
    printf "${BOLD}Valid Dependencies:${NC} %s\n" "$dependencies"
    printf "\n"
}
