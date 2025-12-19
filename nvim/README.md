# Neovim Configuration with LazyVim

This repository contains my Neovim configuration files, structured to utilize LazyVim for plugin management.

## Dependencies

Before installing the plugins, ensure the following dependencies are installed on your machine:

### General Dependencies

- **Neovim**: Ensure Neovim is installed. Version 0.5.0 or higher is required.
- **Git**: Used by LazyVim for plugin management.
- **Node.js**: Required for some LSP servers and plugins.
- **Python3**: Required for some Neovim plugins.
- **Nerd Fonts**: Required for better font rendering in the terminal.

  ```bash
  brew tap homebrew/cask-fonts
  brew install font-meslo-lg-nerd-font
  ```

### Specific Plugin Dependencies

#### Telescope

- **ripgrep**: For improved string searching.
  ```bash
  brew install ripgrep
  ```

#### Venv Selector

- **fd**: to find entries on your filesystem [repo](https://github.com/sharkdp/fd)
  ```bash
  brew install fd
  ```

## Installation

1. Clone the repository to your Neovim configuration directory:

   ```bash
   git clone https://github.com/yourusername/neovim-config ~/.config/nvim
   ```

2. Install the dependencies mentioned above.

3. Open Neovim and install the plugins using LazyVim:

   ```bash
   nvim
   ```

   LazyVim will automatically start installing the plugins.

4. Enjoy your enhanced Neovim setup!

## Contributing

Feel free to contribute by opening issues or submitting pull requests.

## License

This project is licensed under the MIT License.
