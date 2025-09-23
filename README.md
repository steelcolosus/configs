# Dotfiles Management System

A simple, configuration-driven dotfiles manager that uses symlinks to keep your configuration files in sync across multiple systems.

## Overview

This project provides a centralized way to manage configuration files for various applications (tmux, neovim, wezterm, etc.) by storing them in this repository and creating symlinks to their expected locations on your system.

## Features

- **Configuration-driven**: Easy to add new configs by editing `config.yaml`
- **Selective installation**: Install all configs or specific ones
- **Automatic backup**: Backs up existing files before creating symlinks
- **Post-install hooks**: Run commands after installation (reload configs, etc.)
- **Dependency management**: Automatically installs required dependencies
- **Cross-platform**: Works on macOS and Linux

## Prerequisites

- **macOS**: Homebrew (for automatic dependency installation)
- **Linux**: Manual installation of `yq` required

The Makefile will automatically install `yq` via Homebrew on macOS if it's not present.

## Quick Start

1. Clone this repository:

   ```bash
   git clone <your-repo-url>
   cd config-files
   ```

2. List available configurations:

   ```bash
   make list
   ```

3. Install all configurations:

   ```bash
   make install
   ```

4. Or install specific configurations:
   ```bash
   make install-tmux
   make install-nvim
   ```

## Configuration

Edit `config.yaml` to add new configurations:

```yaml
configs:
  tmux:
    source: .tmux.conf
    target: ~/.tmux.conf

  nvim:
    source: nvim
    target: ~/.config/nvim

  # Add your new config here
  zsh:
    source: .zshrc
    target: ~/.zshrc

# Optional post-install commands
post_install:
  tmux:
    - "tmux source-file ~/.tmux.conf 2>/dev/null || echo 'Tmux not running, config will apply on next start'"
  nvim:
    - "echo 'Neovim config updated. Restart nvim to apply changes.'"
```

### Configuration Format

- **Config name**: Friendly identifier (can be anything)
- **source**: Path to the file/directory in this repository
- **target**: Where the symlink should be created on your system
- **post_install**: Optional commands to run after installation

## Available Commands

| Command                 | Description                    |
| ----------------------- | ------------------------------ |
| `make install`          | Install all configurations     |
| `make install-<config>` | Install specific configuration |
| `make uninstall`        | Remove all symlinks            |
| `make list`             | List available configurations  |
| `make backup`           | Backup existing configurations |
| `make help`             | Show help message              |

## Examples

### Install specific configurations

```bash
# Install only tmux configuration
make install-tmux

# Install only Neovim configuration
make install-nvim
```

### Add a new configuration

1. Add your config file to the repository:

   ```bash
   # Example: adding a .gitconfig file
   cp ~/.gitconfig .gitconfig
   ```

2. Edit `config.yaml`:

   ```yaml
   configs:
     # ... existing configs ...
     git:
       source: .gitconfig
       target: ~/.gitconfig
   ```

3. Install the new configuration:
   ```bash
   make install-git
   ```

### Backup and restore

The system automatically backs up existing files before creating symlinks:

```bash
# Backups are stored in ~/.config-backup with timestamps
ls ~/.config-backup/
# Output: .tmux.conf-20231201-143022
```

## Project Structure

```
config-files/
├── README.md              # This file
├── Makefile              # Main automation logic
├── config.yaml           # Configuration mappings
├── .tmux.conf            # Tmux configuration
├── nvim/                 # Neovim configuration directory
│   ├── init.lua
│   └── lua/
└── .github/
    └── copilot-instructions.md
```

## How It Works

1. The `config.yaml` file defines mappings between source files in this repo and target locations
2. The Makefile reads this configuration and creates symlinks
3. Existing files are automatically backed up before linking
4. Post-install commands can be run to reload configurations

## Troubleshooting

### Dependencies

If you get an error about `yq` not being found:

**macOS**: The Makefile should install it automatically via Homebrew
**Linux**: Install manually:

```bash
# Ubuntu/Debian
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Or use your package manager
```

### Permission Issues

If you get permission errors:

```bash
# Make sure you have write access to target directories
mkdir -p ~/.config
chmod 755 ~/.config
```

### Broken Symlinks

To check for broken symlinks:

```bash
# List all symlinks and their targets
make list

# Remove all symlinks and reinstall
make uninstall
make install
```

## Contributing

1. Fork the repository
2. Add your configuration files
3. Update `config.yaml` with your mappings
4. Test with `make install-<your-config>`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
