# Project Overview

This project is desinged as a central hub for config files for tmux, neovim, wezterm or any other config based app you might use on your system.
The overall idea is that all config files or folders with linkfiles should be stored in this repo and then symlinked to the correct location on your system.
all logic should be handled inside the Makefile.
This way you can easily manage your config files and keep them in sync across multiple systems.
