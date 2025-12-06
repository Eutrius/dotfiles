SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.ONESHELL:

# ============================================================================
# PATHS
# ============================================================================
DOTFILES_DIR := $(CURDIR)
SCRIPTS_DIR := $(DOTFILES_DIR)/scripts
CONFIG_DIR := $(HOME)/.config

# Dynamic config discovery (exclude .git and scripts)
CONFIG_NAMES := $(shell find "$(DOTFILES_DIR)" -maxdepth 1 -mindepth 1 -type d \
	! -name '.git' ! -name 'scripts' -exec basename {} \; 2>/dev/null | sort)

# Allow scoping: make install nvim zsh
CONFIG_GOALS := $(filter $(CONFIG_NAMES),$(MAKECMDGOALS))
CONFIGS ?= $(if $(CONFIG_GOALS),$(CONFIG_GOALS),$(CONFIG_NAMES))

export DOTFILES_DIR

.PHONY: help status ls install uninstall link unlink pull deps check \
        common fzf \
        $(CONFIG_NAMES)

# Allow config names as targets (no-op, used for filtering)
$(CONFIG_NAMES):
	@:

# ============================================================================
# HELP
# ============================================================================
help:
	@printf "\n\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m\n"
	@printf "\033[1;36m║              DOTFILES CONFIGURATION MANAGER                  ║\033[0m\n"
	@printf "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m\n\n"
	@printf "\033[1mAvailable configs:\033[0m %s\n\n" "$(CONFIG_NAMES)"
	@printf "\033[1;33mMain Commands:\033[0m\n"
	@printf "  \033[1mmake status\033[0m          Show status of all configs and system info\n"
	@printf "  \033[1mmake install\033[0m         Interactive full install (deps + link + setup)\n"
	@printf "  \033[1mmake uninstall\033[0m       Interactive uninstall\n"
	@printf "  \033[1mmake link\033[0m            Create symlinks only\n"
	@printf "  \033[1mmake unlink\033[0m          Remove symlinks only\n"
	@printf "  \033[1mmake pull\033[0m            Update git submodules\n"
	@printf "\n\033[1;33mDependency Commands:\033[0m\n"
	@printf "  \033[1mmake deps\033[0m            Install all dependencies\n"
	@printf "  \033[1mmake deps nvim\033[0m       Install Neovim + its dependencies\n"
	@printf "  \033[1mmake deps zsh\033[0m        Install Zsh + eza\n"
	@printf "  \033[1mmake deps tmux\033[0m       Install Tmux\n"
	@printf "  \033[1mmake deps common\033[0m     Install common deps (git, curl, fd, fzf, rg)\n"
	@printf "  \033[1mmake fzf\033[0m             Install fzf from git (junegunn/fzf)\n"
	@printf "\n\033[1;33mExamples:\033[0m\n"
	@printf "  make install nvim          # Install nvim config with all deps\n"
	@printf "  make install zsh tmux      # Install multiple configs\n"
	@printf "  make link nvim             # Just symlink nvim (no deps)\n"
	@printf "  make deps nvim             # Just install nvim dependencies\n"
	@printf "  make pull nvim             # Update nvim submodules only\n"
	@printf "\n"

# ============================================================================
# STATUS
# ============================================================================
status:
	@"$(SCRIPTS_DIR)/dotfiles.sh" status
	@echo ""
	@"$(SCRIPTS_DIR)/dotfiles.sh" check-submodules

ls:
	@printf "Available configs:\n"
	@for cfg in $(CONFIG_NAMES); do printf "  - %s\n" "$$cfg"; done

check:
	@printf "\n\033[1;36m=== System Information ===\033[0m\n"
	@"$(SCRIPTS_DIR)/installers/common.sh" check
	@printf "\n\033[1;36m=== Neovim ===\033[0m\n"
	@"$(SCRIPTS_DIR)/installers/nvim.sh" check || true
	@printf "\n\033[1;36m=== Zsh ===\033[0m\n"
	@"$(SCRIPTS_DIR)/installers/zsh.sh" check || true
	@printf "\n\033[1;36m=== Tmux ===\033[0m\n"
	@"$(SCRIPTS_DIR)/installers/tmux.sh" check || true
	@printf "\n\033[1;36m=== fzf ===\033[0m\n"
	@"$(SCRIPTS_DIR)/installers/fzf.sh" check || true

# ============================================================================
# INSTALLATION
# ============================================================================
install:
	@if [ "$(CONFIGS)" = "$(CONFIG_NAMES)" ]; then \
		"$(SCRIPTS_DIR)/dotfiles.sh" interactive; \
	else \
		"$(SCRIPTS_DIR)/dotfiles.sh" install $(CONFIGS); \
	fi

uninstall:
	@if [ "$(CONFIGS)" = "$(CONFIG_NAMES)" ]; then \
		"$(SCRIPTS_DIR)/dotfiles.sh" uninstall; \
	else \
		for cfg in $(CONFIGS); do \
			"$(SCRIPTS_DIR)/dotfiles.sh" uninstall "$$cfg"; \
		done; \
	fi

# ============================================================================
# LINKING
# ============================================================================
link:
	@for cfg in $(CONFIGS); do \
		"$(SCRIPTS_DIR)/dotfiles.sh" link "$$cfg"; \
	done

unlink:
	@for cfg in $(CONFIGS); do \
		"$(SCRIPTS_DIR)/dotfiles.sh" unlink "$$cfg"; \
	done

# ============================================================================
# SUBMODULES
# ============================================================================
pull:
	@"$(SCRIPTS_DIR)/dotfiles.sh" pull $(CONFIGS)

# ============================================================================
# DEPENDENCIES
# ============================================================================
# Syntax: make deps [config...] or make deps common
# Examples: make deps nvim, make deps zsh tmux, make deps common
deps:
	@if [ "$(CONFIG_GOALS)" = "" ]; then \
		"$(SCRIPTS_DIR)/installers/common.sh" all; \
		for cfg in $(CONFIG_NAMES); do \
			case "$$cfg" in \
				nvim) "$(SCRIPTS_DIR)/installers/nvim.sh" deps && "$(SCRIPTS_DIR)/installers/nvim.sh" install;; \
				zsh)  "$(SCRIPTS_DIR)/installers/zsh.sh" all;; \
				tmux) "$(SCRIPTS_DIR)/installers/tmux.sh" all;; \
			esac; \
		done; \
	else \
		for cfg in $(CONFIG_GOALS); do \
			case "$$cfg" in \
				common) "$(SCRIPTS_DIR)/installers/common.sh" all;; \
				nvim) "$(SCRIPTS_DIR)/installers/nvim.sh" deps && "$(SCRIPTS_DIR)/installers/nvim.sh" install;; \
				zsh)  "$(SCRIPTS_DIR)/installers/zsh.sh" all;; \
				tmux) "$(SCRIPTS_DIR)/installers/tmux.sh" all;; \
				*) printf "Unknown config: $$cfg\n";; \
			esac; \
		done; \
	fi

# Allow 'common' as a target for deps
common:
	@:

fzf:
	@"$(SCRIPTS_DIR)/installers/fzf.sh" install

# ============================================================================
# INDIVIDUAL CONFIG SHORTCUTS
# ============================================================================

# Neovim
.PHONY: nvim-install nvim-plugins nvim-uninstall
nvim-install:
	@"$(SCRIPTS_DIR)/dotfiles.sh" install nvim

nvim-plugins:
	@"$(SCRIPTS_DIR)/installers/nvim.sh" plugins

nvim-uninstall:
	@"$(SCRIPTS_DIR)/installers/nvim.sh" uninstall

# Zsh
.PHONY: zsh-install zsh-default
zsh-install:
	@"$(SCRIPTS_DIR)/dotfiles.sh" install zsh

zsh-default:
	@"$(SCRIPTS_DIR)/installers/zsh.sh" set-default

# Tmux
.PHONY: tmux-install tmux-reload
tmux-install:
	@"$(SCRIPTS_DIR)/dotfiles.sh" install tmux

tmux-reload:
	@"$(SCRIPTS_DIR)/installers/tmux.sh" reload

# ============================================================================
# UTILITIES
# ============================================================================
.PHONY: update clean

# Update everything (submodules + fzf)
update: pull
	@"$(SCRIPTS_DIR)/installers/fzf.sh" update || true

# Clean generated files
clean:
	@printf "Nothing to clean yet\n"
