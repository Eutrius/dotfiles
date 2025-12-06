SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.ONESHELL:

DOTFILES_DIR := $(CURDIR)
SCRIPTS_DIR := $(DOTFILES_DIR)/scripts

export DOTFILES_DIR

.PHONY: help init status install uninstall link unlink pull deps

help:
	@printf "\n\033[1;36mDotfiles Manager\033[0m\n\n"
	@printf "\033[1;33mUsage:\033[0m make <command>\n\n"
	@printf "\033[1;33mCommands:\033[0m\n"
	@printf "  \033[1minit\033[0m         Initialize system configuration file\n"
	@printf "  \033[1mstatus\033[0m       Show status of configs and dependencies\n"
	@printf "  \033[1minstall\033[0m      Install configs and dependencies (interactive)\n"
	@printf "  \033[1muninstall\033[0m    Remove configs and dependencies (interactive)\n"
	@printf "  \033[1mlink\033[0m         Create config symlinks (interactive)\n"
	@printf "  \033[1munlink\033[0m       Remove config symlinks (interactive)\n"
	@printf "  \033[1mdeps\033[0m         Install dependencies only (interactive)\n"
	@printf "  \033[1mpull\033[0m         Update git submodules (interactive)\n"
	@printf "\n\033[1;33mSelection:\033[0m 1, 1-3, 1 2 5, or Enter for all\n\n"

init:
	@"$(SCRIPTS_DIR)/dotfiles.sh" init

status:
	@"$(SCRIPTS_DIR)/dotfiles.sh" status

install:
	@"$(SCRIPTS_DIR)/dotfiles.sh" install

uninstall:
	@"$(SCRIPTS_DIR)/dotfiles.sh" uninstall

link:
	@"$(SCRIPTS_DIR)/dotfiles.sh" link

unlink:
	@"$(SCRIPTS_DIR)/dotfiles.sh" unlink

deps:
	@"$(SCRIPTS_DIR)/dotfiles.sh" deps

pull:
	@"$(SCRIPTS_DIR)/dotfiles.sh" pull
