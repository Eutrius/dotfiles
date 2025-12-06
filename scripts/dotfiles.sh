#!/usr/bin/env bash
# Main dotfiles management script
# Handles linking, installation, and configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib/common.sh"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# ============================================================================
# CONFIG DISCOVERY
# ============================================================================

# Get list of available configs (top-level directories)
get_configs() {
    local configs=()
    for dir in "$DOTFILES_DIR"/*/; do
        local name
        name="$(basename "$dir")"
        # Exclude special directories
        case "$name" in
            scripts|.git) continue;;
            *) configs+=("$name");;
        esac
    done
    printf '%s\n' "${configs[@]}"
}

# ============================================================================
# LINKING
# ============================================================================

link_config() {
    local config="$1"
    local src="$DOTFILES_DIR/$config"
    local dest="$CONFIG_DIR/$config"
    
    if [[ ! -d "$src" ]]; then
        log_error "Config source not found: $src"
        return 1
    fi
    
    # Already linked correctly
    if [[ -L "$dest" ]]; then
        local target
        target="$(readlink "$dest")"
        if [[ "${target%/}" == "${src%/}" ]]; then
            log_info "$config: already linked"
            return 0
        else
            log_warn "$config: symlink exists but points to $target"
            return 1
        fi
    fi
    
    # Exists but not a symlink
    if [[ -e "$dest" ]]; then
        log_warn "$config: $dest exists (not a symlink)"
        log_info "Please backup or remove it first"
        return 1
    fi
    
    # Create symlink
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
    
    local target
    target="$(readlink "$dest")"
    if [[ "${target%/}" != "${src%/}" ]]; then
        log_warn "$config: symlink points to $target, not removing"
        return 1
    fi
    
    rm "$dest"
    log_success "$config: unlinked"
}

link_all() {
    local configs
    mapfile -t configs < <(get_configs)
    
    log_step "Linking configs"
    for config in "${configs[@]}"; do
        link_config "$config"
    done
}

unlink_all() {
    local configs
    mapfile -t configs < <(get_configs)
    
    log_step "Unlinking configs"
    for config in "${configs[@]}"; do
        unlink_config "$config"
    done
}

# ============================================================================
# STATUS
# ============================================================================

show_status() {
    local configs
    mapfile -t configs < <(get_configs)
    
    printf "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                     DOTFILES STATUS                          ║${NC}\n"
    printf "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n\n"
    
    printf "${BOLD}System:${NC}\n"
    printf "  OS:       %s\n" "$OS"
    printf "  Arch:     %s\n" "$ARCH"
    printf "  Distro:   %s\n" "$DISTRO"
    printf "  PkgMgr:   %s\n" "$PKG_MANAGER"
    printf "\n"
    
    printf "${BOLD}%-12s %-20s %s${NC}\n" "CONFIG" "LINK STATUS" "NOTES"
    printf "%-12s %-20s %s\n" "──────" "───────────" "─────"
    
    for config in "${configs[@]}"; do
        local src="$DOTFILES_DIR/$config"
        local dest="$CONFIG_DIR/$config"
        local link_status notes=""
        
        if [[ -L "$dest" ]]; then
            local target
            target="$(readlink "$dest")"
            if [[ "${target%/}" == "${src%/}" ]]; then
                link_status="${GREEN}✓ linked${NC}"
            else
                link_status="${YELLOW}→ other${NC}"
                notes="-> $target"
            fi
        elif [[ -e "$dest" ]]; then
            link_status="${YELLOW}! exists${NC}"
            notes="not a symlink"
        else
            link_status="${RED}✗ missing${NC}"
        fi
        
        printf "%-12s %-20b %s\n" "$config" "$link_status" "$notes"
    done
    
    printf "\n"
}

# ============================================================================
# SUBMODULES
# ============================================================================

update_submodules() {
    local configs=("$@")
    
    log_step "Updating submodules"
    
    cd "$DOTFILES_DIR"
    
    if [[ ${#configs[@]} -eq 0 ]]; then
        # Update all
        git submodule update --init --recursive
    else
        # Get submodule paths for specified configs
        local paths=()
        while IFS= read -r path; do
            for config in "${configs[@]}"; do
                if [[ "$path" == "$config" || "$path" == "$config/"* ]]; then
                    paths+=("$path")
                fi
            done
        done < <(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
        
        if [[ ${#paths[@]} -gt 0 ]]; then
            git submodule update --init --recursive -- "${paths[@]}"
        fi
    fi
    
    log_success "Submodules updated"
}

check_submodules() {
    log_step "Checking submodules"
    
    cd "$DOTFILES_DIR"
    
    local uninit=0 outdated=0
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local status_char="${line:0:1}"
        local rest="${line:1}"
        local path="${rest## }"
        path="${path%% *}"
        
        case "$status_char" in
            "-")
                printf "  ${RED}✗${NC} %s (not initialized)\n" "$path"
                ((uninit++))
                ;;
            "+")
                printf "  ${YELLOW}↑${NC} %s (has updates)\n" "$path"
                ((outdated++))
                ;;
            " ")
                printf "  ${GREEN}✓${NC} %s\n" "$path"
                ;;
        esac
    done < <(git submodule status 2>/dev/null)
    
    if (( uninit > 0 || outdated > 0 )); then
        printf "\n${YELLOW}Run 'make pull' to update submodules${NC}\n"
    fi
}

# ============================================================================
# INSTALLATION
# ============================================================================

install_config() {
    local config="$1"
    local installer="$SCRIPT_DIR/installers/${config}.sh"
    
    log_step "Installing $config"
    
    # Run config-specific installer if it exists
    if [[ -x "$installer" ]]; then
        "$installer" all
    else
        log_info "No specific installer for $config"
    fi
    
    # Link the config
    link_config "$config"
    
    # Post-install hooks
    case "$config" in
        zsh)
            # Setup .zshrc
            local source_line="source $DOTFILES_DIR/zsh/init.zsh"
            local zshrc="$HOME/.zshrc"
            touch "$zshrc"
            if ! grep -Fxq "$source_line" "$zshrc"; then
                echo "$source_line" >> "$zshrc"
                log_success "Added source line to .zshrc"
            fi
            ;;
        nvim)
            # Sync plugins
            if command_exists nvim && is_interactive; then
                if ask_yes_no "Sync Neovim plugins now?" "y"; then
                    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
                fi
            fi
            ;;
        tmux)
            # Reload if in tmux
            if [[ -n "${TMUX:-}" ]] && is_interactive; then
                if ask_yes_no "Reload tmux config?" "y"; then
                    tmux source-file "$DOTFILES_DIR/tmux/tmux.conf" 2>/dev/null || true
                fi
            fi
            ;;
    esac
}

uninstall_config() {
    local config="$1"
    local installer="$SCRIPT_DIR/installers/${config}.sh"
    
    log_step "Uninstalling $config"
    
    # Unlink first
    unlink_config "$config"
    
    # Config-specific cleanup
    case "$config" in
        zsh)
            local source_line="source $DOTFILES_DIR/zsh/init.zsh"
            local zshrc="$HOME/.zshrc"
            if [[ -f "$zshrc" ]]; then
                grep -Fxv "$source_line" "$zshrc" > "$zshrc.tmp" || true
                mv "$zshrc.tmp" "$zshrc"
                log_success "Removed source line from .zshrc"
            fi
            ;;
        nvim)
            # Offer to remove nvim nightly
            if [[ -x "$installer" ]]; then
                "$installer" uninstall 2>/dev/null || true
            fi
            ;;
    esac
}

# ============================================================================
# INTERACTIVE MENUS
# ============================================================================

interactive_install() {
    local configs
    mapfile -t configs < <(get_configs)
    
    printf "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                    INTERACTIVE INSTALLER                     ║${NC}\n"
    printf "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n\n"
    
    # Show current status
    printf "${BOLD}Current status:${NC}\n"
    for config in "${configs[@]}"; do
        local dest="$CONFIG_DIR/$config"
        if [[ -L "$dest" ]]; then
            printf "  ${GREEN}●${NC} %s (linked)\n" "$config"
        else
            printf "  ○ %s\n" "$config"
        fi
    done
    
    printf "\n"
    
    # Select configs to install
    mapfile -t selected < <(select_items "Select configs to install:" "${configs[@]}")
    
    if [[ ${#selected[@]} -eq 0 ]]; then
        log_info "No configs selected"
        return 0
    fi
    
    # Update submodules for selected configs
    update_submodules "${selected[@]}"
    
    # Install common deps first
    "$SCRIPT_DIR/installers/common.sh" all
    
    # Install each config
    for config in "${selected[@]}"; do
        install_config "$config"
    done
    
    printf "\n${GREEN}Installation complete!${NC}\n\n"
}

interactive_uninstall() {
    local configs
    mapfile -t configs < <(get_configs)
    
    # Filter to only linked configs
    local linked=()
    for config in "${configs[@]}"; do
        local dest="$CONFIG_DIR/$config"
        if [[ -L "$dest" ]]; then
            linked+=("$config")
        fi
    done
    
    if [[ ${#linked[@]} -eq 0 ]]; then
        log_info "No configs are currently linked"
        return 0
    fi
    
    printf "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                   INTERACTIVE UNINSTALLER                    ║${NC}\n"
    printf "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n\n"
    
    mapfile -t selected < <(select_items "Select configs to uninstall:" "${linked[@]}")
    
    if [[ ${#selected[@]} -eq 0 ]]; then
        log_info "No configs selected"
        return 0
    fi
    
    for config in "${selected[@]}"; do
        uninstall_config "$config"
    done
    
    printf "\n${GREEN}Uninstallation complete!${NC}\n\n"
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    cat <<EOF

${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}
${CYAN}║              DOTFILES MANAGEMENT SCRIPT                      ║${NC}
${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}

Usage: $(basename "$0") <command> [configs...]

${BOLD}Commands:${NC}
    status              Show status of all configs
    link [configs]      Create symlinks for configs
    unlink [configs]    Remove symlinks for configs
    install [configs]   Full installation (deps + link + setup)
    uninstall [configs] Full uninstallation
    pull [configs]      Update git submodules
    check-submodules    Check submodule status
    interactive         Interactive installation menu
    
${BOLD}Examples:${NC}
    $(basename "$0") status
    $(basename "$0") install nvim zsh
    $(basename "$0") link tmux
    $(basename "$0") pull

${BOLD}Config-specific installers:${NC}
    scripts/installers/nvim.sh    - Neovim + dependencies
    scripts/installers/zsh.sh     - Zsh + eza + starship
    scripts/installers/tmux.sh    - Tmux
    scripts/installers/fzf.sh     - fzf from git
    scripts/installers/common.sh  - Common dependencies

EOF
}

main() {
    local cmd="${1:-}"
    shift || true
    
    case "$cmd" in
        status)
            show_status
            ;;
        link)
            if [[ $# -eq 0 ]]; then
                link_all
            else
                for config in "$@"; do
                    link_config "$config"
                done
            fi
            ;;
        unlink)
            if [[ $# -eq 0 ]]; then
                unlink_all
            else
                for config in "$@"; do
                    unlink_config "$config"
                done
            fi
            ;;
        install)
            if [[ $# -eq 0 ]]; then
                interactive_install
            else
                update_submodules "$@"
                "$SCRIPT_DIR/installers/common.sh" all
                for config in "$@"; do
                    install_config "$config"
                done
            fi
            ;;
        uninstall)
            if [[ $# -eq 0 ]]; then
                interactive_uninstall
            else
                for config in "$@"; do
                    uninstall_config "$config"
                done
            fi
            ;;
        pull)
            update_submodules "$@"
            ;;
        check-submodules|submodules)
            check_submodules
            ;;
        interactive|i)
            interactive_install
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
