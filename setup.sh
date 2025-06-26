#!/usr/bin/env bash
set -e

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
AVAILABLE_CONFIGS=()

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

init_submodules() {
    log_info "Checking for submodules..."
    
    if [ ! -d "$DOTFILES_DIR/.git/modules" ] || ! git submodule status | grep -qv ' '; then
        log_info "Initializing and updating submodules..."
        git submodule update --init --recursive
    else
        log_success "Submodules already initialized"
    fi
}

discover_configs() {
    AVAILABLE_CONFIGS=()
    for dir in "$DOTFILES_DIR"/*; do
        if [ -d "$dir" ]; then
            AVAILABLE_CONFIGS+=("$(basename "$dir")")
        fi
    done
}

is_linked() {
    local config_name="$1"
    [ -L "$CONFIG_DIR/$config_name" ] && return 0 || return 1
}

post_install_commands() {
    local config="$1"
    
    case "$config" in
        "zsh")
            log_info "Setting up zsh configuration..."
            if ! grep -q "source $DOTFILES_DIR/zsh/init.zsh" ~/.zshrc 2>/dev/null; then
                echo "source $DOTFILES_DIR/zsh/init.zsh" >> ~/.zshrc
                log_success "Added zsh source line to ~/.zshrc"
            else
                log_info "zsh source line already exists in ~/.zshrc"
            fi
            ;;
        
        *)
            ;;
    esac
}

show_menu() {
    echo
    echo "🛠️  Available configurations:"
    echo "─────────────────────────────"
    
    for i in "${!AVAILABLE_CONFIGS[@]}"; do
        local idx=$((i + 1))
        local config="${AVAILABLE_CONFIGS[$i]}"
        
        if is_linked "$config"; then
            printf "%2d) %-15s ${GREEN}(linked)${NC}\n" "$idx" "$config"
        else
            printf "%2d) %-15s\n" "$idx" "$config"
        fi
    done
    
    printf "%2d) %-15s ${BLUE}(install all)${NC}\n" "$(( ${#AVAILABLE_CONFIGS[@]} + 1 ))" "all"
    echo "─────────────────────────────"
}

ensure_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        log_success "Created config directory: $CONFIG_DIR"
    fi
}

install_config() {
    local config="$1"
    local target="$CONFIG_DIR/$config"
    local source="$DOTFILES_DIR/$config"
    
    if is_linked "$config"; then
        log_warning "$config is already linked — skipping"
        return 0
    fi
    
    if [ -e "$target" ]; then
        log_warning "$target exists and is not a symlink — skipping"
        log_info "Remove or backup the existing file/directory first"
        return 1
    fi
    
    if [ ! -d "$source" ]; then
        log_error "Source directory $source does not exist"
        return 1
    fi
    
    log_info "Linking $config..."
    ln -s "$source" "$target"
    log_success "Linked $config → $target"
    
    post_install_commands "$config"
    
    return 0
}

process_selection() {
    local selection="$1"
    local installed_count=0
    
    if [ "$selection" = "$(( ${#AVAILABLE_CONFIGS[@]} + 1 ))" ]; then
        log_info "Installing all configurations..."
        for config in "${AVAILABLE_CONFIGS[@]}"; do
            if install_config "$config"; then
                ((installed_count++))
            fi
        done
        return $installed_count
    fi
    
    declare -A selected_configs=()
    
    if [[ "$selection" =~ [[:space:]] ]]; then
        for idx in $selection; do
            if [[ "$idx" =~ ^[0-9]+$ ]]; then
                config_idx=$((idx - 1))
                if [ "$config_idx" -ge 0 ] && [ "$config_idx" -lt "${#AVAILABLE_CONFIGS[@]}" ]; then
                    selected_configs["${AVAILABLE_CONFIGS[$config_idx]}"]=1
                else
                    log_warning "Invalid index: $idx"
                fi
            else
                log_error "Invalid input: '$idx' is not a number"
            fi
        done
    else
        for ((i = 0; i < ${#selection}; i++)); do
            idx="${selection:$i:1}"
            if [[ "$idx" =~ ^[0-9]$ ]]; then
                config_idx=$((idx - 1))
                if [ "$config_idx" -ge 0 ] && [ "$config_idx" -lt "${#AVAILABLE_CONFIGS[@]}" ]; then
                    selected_configs["${AVAILABLE_CONFIGS[$config_idx]}"]=1
                else
                    log_warning "Invalid index: $idx"
                fi
            else
                log_error "Invalid input: '$idx' is not a number"
            fi
        done
    fi
    
    for config in "${!selected_configs[@]}"; do
        if install_config "$config"; then
            ((installed_count++))
        fi
    done
    
    return $installed_count
}

main() {
    echo "🚀 Dotfiles Configuration Manager"
    echo "================================="
    
    init_submodules
    discover_configs
    ensure_config_dir
    
    if [ ${#AVAILABLE_CONFIGS[@]} -eq 0 ]; then
        log_error "No configuration directories found in $DOTFILES_DIR"
        exit 1
    fi
    
    while true; do
        show_menu
        echo
        read -rp "Enter config numbers (e.g., '1 3' or '13'), 'all', or press Enter to quit: " selection
        
        if [ -z "$selection" ]; then
            echo
            log_success "Thanks for using the dotfiles manager! 👋"
            break
        fi
        
        echo
        if process_selection "$selection"; then
            installed_count=$?
            if [ $installed_count -gt 0 ]; then
                echo
                log_success "Successfully processed $installed_count configuration(s)"
            fi
        fi
        
        echo
        read -rp "Press Enter to continue..."
    done
}

main "$@"
