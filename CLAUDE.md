# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for Unix-like systems (macOS and Linux/Ubuntu) that automates development environment setup. The repository contains shell configuration files, installation scripts, and personal preferences for various development tools.

## Key Files and Structure

- **start.sh**: Main installation script that sets up the entire development environment
  - Creates symlinks for dotfiles (gitconfig, gitignore_global, tmux.conf, bash_profile)
  - Installs essential packages via Homebrew (macOS) or apt (Linux)
  - Installs Starship prompt, mise (development environment manager), and Nerd Fonts
  - Handles platform-specific configurations

- **bash_profile**: Primary shell configuration that:
  - Sources aliases from alias.sh
  - Sources private secrets from ~/.dotfiles_private/secret.sh (if exists)
  - Configures development tools (Go, Rust, mise, Starship)
  - Sets up bash completion
  - Manages PATH for various tools (Homebrew, LM Studio, Windsurf, OrbStack)

- **alias.sh**: Common shell aliases including custom git trainer wrapper

- **gitconfig**: Git configuration with useful aliases and settings
  - Sets up Git LFS filters
  - Defines common git aliases (co, br, st, etc.)
  - Configures merge tools for XCode projects

- **tmux.conf**: Terminal multiplexer configuration
  - Changes prefix key to C-q
  - Enables mouse support
  - Configures pane splitting with | and -

- **Dockerfile**: Ubuntu test environment for validating dotfiles setup

## Development Tasks

### Testing Changes
To test dotfiles changes in an isolated Ubuntu environment:
```bash
docker build -t dotfiles-test .
docker run -it dotfiles-test
```

### Running the Setup
```bash
./start.sh
```

### Modifying Configurations
- Shell aliases: Edit `alias.sh`
- Shell environment: Edit `bash_profile`
- Git configuration: Edit `gitconfig`
- Installation steps: Edit `start.sh`

## Important Notes

- The repository expects a sibling private repository at `~/.dotfiles_private` for sensitive configurations
- The setup script requires sudo privileges on Linux systems
- 1Password SSH agent integration is expected (see README.md for setup instructions)

## Platform-Specific Behavior

### macOS
- Installs packages via Homebrew
- Switches default shell to Homebrew's bash (newer version)
- Installs Hack Nerd Font via Homebrew

### Linux/Ubuntu
- Installs packages via apt
- Downloads and installs FiraCode Nerd Font manually
- Runs with sudo privileges automatically