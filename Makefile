# Variables
CONFIG_DIR := $(shell pwd)
CONFIG_FILE := config.yaml
BACKUP_DIR := $(HOME)/.config-backup

.PHONY: all install uninstall list backup help install-yq

# Default target: show help
all: help

# Install yq if not present
install-yq:
	@if ! command -v yq >/dev/null 2>&1; then \
		echo "Installing yq dependency..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install yq; \
		elif [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
			echo "Please install yq manually: https://github.com/mikefarah/yq#install"; \
			exit 1; \
		else \
			echo "Please install yq manually: https://github.com/mikefarah/yq#install"; \
			exit 1; \
		fi; \
	fi

# Install all configurations
install: install-yq backup
	@echo "Installing configurations from $(CONFIG_FILE)..."
	@yq eval '.configs | to_entries | .[] | .key + ":" + .value.source + ":" + .value.target' $(CONFIG_FILE) | while IFS=: read -r config_name source_path target_path; do \
		expanded_target=$$(eval echo $$target_path); \
		full_source_path="$(CONFIG_DIR)/$$source_path"; \
		if [ -e "$$full_source_path" ]; then \
			target_dir=$$(dirname "$$expanded_target"); \
			mkdir -p "$$target_dir"; \
			ln -sfn "$$full_source_path" "$$expanded_target"; \
			echo "✓ Linked $$config_name ($$source_path) -> $$expanded_target"; \
		else \
			echo "✗ Source not found: $$full_source_path"; \
		fi; \
	done
	@echo "Running post-install commands..."
	@yq eval '.post_install | to_entries | .[] | .key + ":" + (.value | join(";"))' $(CONFIG_FILE) 2>/dev/null | while IFS=: read -r config commands; do \
		if [ -n "$$commands" ]; then \
			echo "Running post-install for $$config..."; \
			echo "$$commands" | tr ';' '\n' | while read -r cmd; do \
				eval "$$cmd"; \
			done; \
		fi; \
	done || true

# Install specific configuration
install-%: install-yq
	@echo "Installing configuration: $*"
	@source_path=$$(yq eval '.configs["$*"].source' $(CONFIG_FILE)); \
	target_path=$$(yq eval '.configs["$*"].target' $(CONFIG_FILE)); \
	if [ "$$source_path" = "null" ] || [ "$$target_path" = "null" ]; then \
		echo "Configuration '$*' not found in $(CONFIG_FILE)"; \
		echo "Available configurations:"; \
		yq eval '.configs | keys | .[]' $(CONFIG_FILE) | sed 's/^/  /'; \
		exit 1; \
	fi; \
	expanded_target=$$(eval echo $$target_path); \
	full_source_path="$(CONFIG_DIR)/$$source_path"; \
	if [ -e "$$full_source_path" ]; then \
		target_dir=$$(dirname "$$expanded_target"); \
		mkdir -p "$$target_dir"; \
		if [ -e "$$expanded_target" ] && [ ! -L "$$expanded_target" ]; then \
			backup_path="$(BACKUP_DIR)/$*-$$(date +%Y%m%d-%H%M%S)"; \
			mkdir -p "$$(dirname "$$backup_path")"; \
			mv "$$expanded_target" "$$backup_path"; \
			echo "Backed up existing file to $$backup_path"; \
		fi; \
		ln -sfn "$$full_source_path" "$$expanded_target"; \
		echo "✓ Linked $* ($$source_path) -> $$expanded_target"; \
		commands=$$(yq eval '.post_install["$*"] // []' $(CONFIG_FILE) | yq eval '. | join(";")' -); \
		if [ "$$commands" != "null" ] && [ -n "$$commands" ]; then \
			echo "Running post-install commands for $*..."; \
			echo "$$commands" | tr ';' '\n' | while read -r cmd; do \
				eval "$$cmd"; \
			done; \
		fi; \
	else \
		echo "✗ Source not found: $$full_source_path"; \
		exit 1; \
	fi

# Backup existing configurations
backup: install-yq
	@echo "Creating backup of existing configurations..."
	@mkdir -p $(BACKUP_DIR)
	@yq eval '.configs | to_entries | .[] | .value.target' $(CONFIG_FILE) | while read -r target_path; do \
		expanded_target=$$(eval echo $$target_path); \
		if [ -e "$$expanded_target" ] && [ ! -L "$$expanded_target" ]; then \
			backup_name=$$(basename "$$expanded_target"); \
			backup_path="$(BACKUP_DIR)/$$backup_name-$$(date +%Y%m%d-%H%M%S)"; \
			cp -r "$$expanded_target" "$$backup_path"; \
			echo "Backed up $$expanded_target to $$backup_path"; \
		fi; \
	done

# List all available configurations
list: install-yq
	@echo "Available configurations:"
	@yq eval '.configs | to_entries | .[] | "  " + .key + " (source: " + .value.source + ") -> " + .value.target' $(CONFIG_FILE)

# Uninstall all configurations
uninstall: install-yq
	@echo "Uninstalling configurations..."
	@yq eval '.configs | to_entries | .[] | .value.target' $(CONFIG_FILE) | while read -r target_path; do \
		expanded_target=$$(eval echo $$target_path); \
		if [ -L "$$expanded_target" ]; then \
			rm "$$expanded_target"; \
			echo "✓ Removed symlink: $$expanded_target"; \
		elif [ -e "$$expanded_target" ]; then \
			echo "⚠ Not a symlink, skipping: $$expanded_target"; \
		fi; \
	done

# Show help
help:
	@echo "Dotfiles Management System"
	@echo ""
	@echo "Usage:"
	@echo "  make install           Install all configurations"
	@echo "  make install-<config>  Install specific configuration (e.g., make install-tmux)"
	@echo "  make uninstall         Remove all symlinks"
	@echo "  make list              List available configurations"
	@echo "  make backup            Backup existing configurations"
	@echo "  make help              Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make install-tmux      Install only tmux configuration"
	@echo "  make install-nvim      Install only Neovim configuration"
	@echo ""
	@echo "Dependencies will be installed automatically (requires Homebrew on macOS)"
