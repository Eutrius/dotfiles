SHELL := /usr/bin/bash
SCRIPT := .scripts/dotfiles.sh
REGISTRY := .config

CYAN := $(shell printf '\033[0;36m')
GREEN := $(shell printf '\033[0;32m')
YELLOW := $(shell printf '\033[0;33m')
RED := $(shell printf '\033[0;31m')
BOLD := $(shell printf '\033[1m')
NC := $(shell printf '\033[0m')

PROGRAMS := $(shell awk -F'|' '/^\[programs\]/{p=1;next} /^\[/{p=0} p && /^[a-z]/{n=split($$1,a,","); for(i=1;i<=n;i++) print a[i]}' $(REGISTRY) 2>/dev/null)
DEPENDENCIES := $(shell awk -F'|' '/^\[dependencies\]/{p=1;next} /^\[/{p=0} p && /^[a-z]/{n=split($$1,a,","); for(i=1;i<=n;i++) print a[i]}' $(REGISTRY) 2>/dev/null)
CONFIGS := $(shell awk -F'|' '/^\[configs\]/{p=1;next} /^\[/{p=0} p && /^[a-z]/{n=split($$1,a,","); for(i=1;i<=n;i++) print a[i]}' $(REGISTRY) 2>/dev/null)

TARGETS := help init status install remove link unlink deps remove-deps pull clean

GOALS := $(MAKECMDGOALS)
CMD_TARGETS := $(filter $(TARGETS),$(GOALS))
CMD_ARGS := $(filter-out $(TARGETS),$(GOALS))

VALID_PROGRAMS := $(filter $(PROGRAMS),$(CMD_ARGS))
VALID_DEPENDENCIES := $(filter $(DEPENDENCIES),$(CMD_ARGS))
VALID_CONFIGS := $(filter $(CONFIGS),$(CMD_ARGS))

INVALID_PROGRAMS := $(filter-out $(PROGRAMS),$(CMD_ARGS))
INVALID_DEPENDENCIES := $(filter-out $(DEPENDENCIES),$(CMD_ARGS))
INVALID_CONFIGS := $(filter-out $(CONFIGS),$(CMD_ARGS))

ifneq ($(CMD_ARGS),)
UNIQUE_ARGS := $(sort $(CMD_ARGS))
.PHONY: $(UNIQUE_ARGS)
$(UNIQUE_ARGS):
	@:
endif

.PHONY: $(TARGETS)

help:
	@$(SCRIPT) help

init:
	@$(SCRIPT) init

status:
	@$(SCRIPT) status

install:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_PROGRAMS),)
ifneq ($(VALID_PROGRAMS),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_PROGRAMS)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid program(s): $(INVALID_PROGRAMS). Valid options: $(PROGRAMS)\n"
endif
endif
ifneq ($(VALID_PROGRAMS),)
	@printf "\n$(BOLD)$(CYAN)==> Installing: $(VALID_PROGRAMS)$(NC)\n"
	@$(SCRIPT) install $(VALID_PROGRAMS)
endif
else
	@$(SCRIPT) install
endif

remove:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_PROGRAMS),)
ifneq ($(VALID_PROGRAMS),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_PROGRAMS)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid program(s): $(INVALID_PROGRAMS). Valid options: $(PROGRAMS)\n"
endif
endif
ifneq ($(VALID_PROGRAMS),)
	@printf "\n$(BOLD)$(CYAN)==> Removing: $(VALID_PROGRAMS)$(NC)\n"
	@$(SCRIPT) remove $(VALID_PROGRAMS)
endif
else
	@$(SCRIPT) remove
endif

link:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_CONFIGS),)
ifneq ($(VALID_CONFIGS),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_CONFIGS)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid config(s): $(INVALID_CONFIGS). Valid options: $(CONFIGS)\n"
endif
endif
ifneq ($(VALID_CONFIGS),)
	@printf "\n$(BOLD)$(CYAN)==> Linking: $(VALID_CONFIGS)$(NC)\n"
	@$(SCRIPT) link $(VALID_CONFIGS)
endif
else
	@$(SCRIPT) link
endif

unlink:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_CONFIGS),)
ifneq ($(VALID_CONFIGS),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_CONFIGS)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid config(s): $(INVALID_CONFIGS). Valid options: $(CONFIGS)\n"
endif
endif
ifneq ($(VALID_CONFIGS),)
	@printf "\n$(BOLD)$(CYAN)==> Unlinking: $(VALID_CONFIGS)$(NC)\n"
	@$(SCRIPT) unlink $(VALID_CONFIGS)
endif
else
	@$(SCRIPT) unlink
endif

deps:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_DEPENDENCIES),)
ifneq ($(VALID_DEPENDENCIES),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_DEPENDENCIES)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid dependency(s): $(INVALID_DEPENDENCIES). Valid options: $(DEPENDENCIES)\n"
endif
endif
ifneq ($(VALID_DEPENDENCIES),)
	@printf "\n$(BOLD)$(CYAN)==> Installing dependencies: $(VALID_DEPENDENCIES)$(NC)\n"
	@$(SCRIPT) deps $(VALID_DEPENDENCIES)
endif
else
	@$(SCRIPT) deps
endif

remove-deps:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_DEPENDENCIES),)
ifneq ($(VALID_DEPENDENCIES),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_DEPENDENCIES)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid dependency(s): $(INVALID_DEPENDENCIES). Valid options: $(DEPENDENCIES)\n"
endif
endif
ifneq ($(VALID_DEPENDENCIES),)
	@printf "\n$(BOLD)$(CYAN)==> Removing dependencies: $(VALID_DEPENDENCIES)$(NC)\n"
	@$(SCRIPT) remove-deps $(VALID_DEPENDENCIES)
endif
else
	@$(SCRIPT) remove-deps
endif

pull:
ifneq ($(CMD_ARGS),)
ifneq ($(INVALID_CONFIGS),)
ifneq ($(VALID_CONFIGS),)
	@printf "$(YELLOW)[Warn]$(NC) Ignoring invalid: $(INVALID_CONFIGS)\n"
else
	@printf "$(RED)[Error]$(NC) Invalid config(s): $(INVALID_CONFIGS). Valid options: $(CONFIGS)\n"
endif
endif
ifneq ($(VALID_CONFIGS),)
	@printf "\n$(BOLD)$(CYAN)==> Updating submodules: $(VALID_CONFIGS)$(NC)\n"
	@$(SCRIPT) pull $(VALID_CONFIGS)
endif
else
	@$(SCRIPT) pull
endif

clean:
	@printf "\n$(BOLD)$(CYAN)==> Cleaning generated files$(NC)\n"
	@rm -f .system
	@printf "$(GREEN)[OK]$(NC) Clean complete\n"
