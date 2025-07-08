# Dotfiles

Personal development environment configuration for macOS and Linux.

## Prerequisites

### macOS
Install Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### SSH Agent Setup (Optional)
For 1Password SSH integration:
1. Install 1Password
2. Configure the vault in `~/.config/1Password/ssh/agent.toml`
3. See [1Password SSH docs](https://developer.1password.com/docs/ssh/agent/config/#from-the-1password-app)

## Installation

1. Clone the repositories:
```bash
git clone https://github.com/keitaoouchi/dotfiles_public.git .dotfiles_public
git clone https://github.com/keitaoouchi/dotfiles_private.git .dotfiles_private
```

2. Run the setup:
```bash
cd .dotfiles_public
./start.sh
```

## Testing

Test the setup in Ubuntu using Docker:
```bash
docker build -t dotfiles-test .
docker run -it dotfiles-test
```