# Variables
SHELL := /bin/bash
CONFIG_DIR := $(shell pwd)
CONFIG_FILE := config.yaml
BACKUP_DIR := $(HOME)/.config-backup
YQ_VERSION := v4.40.5
LOCAL_BIN := $(HOME)/.local/bin

# Prefer the repo-managed yq in ~/.local/bin so every recipe (and install.sh)
# sees it regardless of the user's default PATH
export PATH := $(LOCAL_BIN):$(PATH)

.PHONY: all install uninstall list backup restore help install-yq

# Default target: show help
all: help

# Install yq if not present
install-yq:
	@if ! command -v yq >/dev/null 2>&1; then \
		echo "Installing yq dependency..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install yq; \
		elif [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
			case "$$(uname -m)" in \
				x86_64) yq_arch="amd64" ;; \
				aarch64|arm64) yq_arch="arm64" ;; \
				armv7l) yq_arch="arm" ;; \
				*) echo "Error: Unsupported architecture $$(uname -m). Please install yq manually: https://github.com/mikefarah/yq#install"; exit 1 ;; \
			esac; \
			yq_binary="yq_linux_$$yq_arch"; \
			echo "Detected Linux ($$yq_arch). Attempting to install yq to $(LOCAL_BIN)..."; \
			mkdir -p $(LOCAL_BIN); \
			if command -v wget >/dev/null 2>&1; then \
				wget -qO $(LOCAL_BIN)/yq https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/$$yq_binary; \
			elif command -v curl >/dev/null 2>&1; then \
				curl -fL -o $(LOCAL_BIN)/yq https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/$$yq_binary; \
			else \
				echo "Error: Neither wget nor curl found. Please install yq manually."; \
				exit 1; \
			fi; \
			if [ ! -s $(LOCAL_BIN)/yq ]; then \
				echo "Error: Download failed, $(LOCAL_BIN)/yq is empty. Please install yq manually: https://github.com/mikefarah/yq#install"; \
				rm -f $(LOCAL_BIN)/yq; \
				exit 1; \
			fi; \
			chmod +x $(LOCAL_BIN)/yq; \
			if ! $(LOCAL_BIN)/yq --version >/dev/null 2>&1; then \
				echo "Error: Downloaded yq binary is not runnable. Please install yq manually: https://github.com/mikefarah/yq#install"; \
				exit 1; \
			fi; \
			echo "yq installed to $(LOCAL_BIN)/yq"; \
			echo "Please ensure $(LOCAL_BIN) is in your PATH."; \
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
	@yq eval '.configs | to_entries | .[] | .key + "\t" + .value.target' $(CONFIG_FILE) | while IFS=$$'\t' read -r config_name target_path; do \
		expanded_target=$$(eval echo $$target_path); \
		if [ -e "$$expanded_target" ] && [ ! -L "$$expanded_target" ]; then \
			backup_path="$(BACKUP_DIR)/$$config_name-$$(date +%Y%m%d-%H%M%S)"; \
			cp -r "$$expanded_target" "$$backup_path"; \
			echo "Backed up $$expanded_target to $$backup_path"; \
		fi; \
	done

# Restore the most recent backup for a specific configuration
restore-%: install-yq
	@config_name="$*"; \
	target_path=$$(yq eval ".configs[\"$$config_name\"].target" $(CONFIG_FILE)); \
	if [ "$$target_path" = "null" ]; then \
		echo "Error: Configuration '$$config_name' not found in $(CONFIG_FILE)"; \
		exit 1; \
	fi; \
	expanded_target=$$(eval echo $$target_path); \
	latest_backup=$$(ls -1dt $(BACKUP_DIR)/$$config_name-* 2>/dev/null | head -n1); \
	if [ -z "$$latest_backup" ]; then \
		echo "No backup found for '$$config_name' in $(BACKUP_DIR)"; \
		exit 1; \
	fi; \
	if [ -L "$$expanded_target" ]; then rm "$$expanded_target"; fi; \
	cp -r "$$latest_backup" "$$expanded_target"; \
	echo "✓ Restored $$config_name from $$latest_backup -> $$expanded_target"

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
	@echo "  make restore-<config>  Restore most recent backup for a configuration"
	@echo "  make help              Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make install-tmux      Install only tmux configuration"
	@echo "  make install-nvim      Install only Neovim configuration"
	@echo "  make restore-tmux      Restore tmux configuration from its last backup"
	@echo ""
	@echo "Dependencies will be installed automatically (requires Homebrew on macOS)"
