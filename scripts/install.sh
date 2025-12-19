#!/bin/bash

# scripts/install.sh
# Handles installation of configurations defined in config.yaml

CONFIG_FILE="config.yaml"
BACKUP_DIR="$HOME/.config-backup"
CONFIG_DIR=$(pwd)

# Function to install a single configuration
install_config() {
    local config_name=$1
    
    echo "Installing configuration: $config_name"
    
    # Read source and target from config.yaml
    source_path=$(yq eval ".configs[\"$config_name\"].source" "$CONFIG_FILE")
    target_path=$(yq eval ".configs[\"$config_name\"].target" "$CONFIG_FILE")
    
    if [ "$source_path" = "null" ] || [ "$target_path" = "null" ]; then
        echo "Error: Configuration '$config_name' not found in $CONFIG_FILE"
        return 1
    fi
    
    # Expand target path (handle ~)
    expanded_target=$(eval echo "$target_path")
    full_source_path="$CONFIG_DIR/$source_path"
    
    if [ ! -e "$full_source_path" ]; then
        echo "✗ Source not found: $full_source_path"
        return 1
    fi
    
    # Create target directory
    target_dir=$(dirname "$expanded_target")
    mkdir -p "$target_dir"
    
    # Backup existing file/directory if it's not already a symlink
    if [ -e "$expanded_target" ] && [ ! -L "$expanded_target" ]; then
        backup_path="$BACKUP_DIR/$config_name-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$(dirname "$backup_path")"
        mv "$expanded_target" "$backup_path"
        echo "Backed up existing file to $backup_path"
    fi
    
    # Create symlink
    ln -sfn "$full_source_path" "$expanded_target"
    echo "✓ Linked $config_name ($source_path) -> $expanded_target"
    
    # Run post-install commands
    commands=$(yq eval ".post_install[\"$config_name\"] // [] | join(\";\")" "$CONFIG_FILE")
    if [ "$commands" != "null" ] && [ -n "$commands" ]; then
        echo "Running post-install commands for $config_name..."
        echo "$commands" | tr ';' '\n' | while read -r cmd; do
            eval "$cmd"
        done
    fi
}

# Main execution
if [ -n "$1" ]; then
    # Install specific config
    install_config "$1"
else
    # Install all configs
    echo "Installing all configurations..."
    yq eval '.configs | keys | .[]' "$CONFIG_FILE" | while read -r config; do
        install_config "$config"
    done
fi
