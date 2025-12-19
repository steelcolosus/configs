# Variables
SHELL := /bin/bash
CONFIG_DIR := $(shell pwd)
CONFIG_FILE := config.yaml
BACKUP_DIR := $(HOME)/.config-backup
YQ_VERSION := v4.40.5
YQ_BINARY := yq_linux_amd64
LOCAL_BIN := $(HOME)/.local/bin

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
			echo "Detected Linux. Attempting to install yq to $(LOCAL_BIN)..."; \
			mkdir -p $(LOCAL_BIN); \
			if command -v wget >/dev/null 2>&1; then \
				wget -qO $(LOCAL_BIN)/yq https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/$(YQ_BINARY); \
			elif command -v curl >/dev/null 2>&1; then \
				curl -L -o $(LOCAL_BIN)/yq https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/$(YQ_BINARY); \
			else \
				echo "Error: Neither wget nor curl found. Please install yq manually."; \
				exit 1; \
			fi; \
			chmod +x $(LOCAL_BIN)/yq; \
			echo "yq installed to $(LOCAL_BIN)/yq"; \
			echo "Please ensure $(LOCAL_BIN) is in your PATH."; \
			export PATH="$(LOCAL_BIN):$$PATH"; \
		else \
			echo "Unsupported OS. Please install yq manually: https://github.com/mikefarah/yq#install"; \
			exit 1; \
		fi; \
	fi

# Install all configurations
install: install-yq
	@./scripts/install.sh

# Install specific configuration
install-%: install-yq
	@./scripts/install.sh $*

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
