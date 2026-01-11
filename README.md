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

---

## Chezmoi Migration (New!)

This repository is being migrated to [chezmoi](https://www.chezmoi.io/) for better dotfiles management with 1Password integration.

### Prerequisites for Chezmoi

1. **1Password Account & App**
   - Install 1Password from https://1password.com/
   - Create a vault named "Private"
   - Add items:
     - `dotfiles` with fields: `git_name`, `git_email`, `git_signing_key`
     - `secrets` with field: `github_token` (and other secrets)

2. **1Password CLI**
   ```bash
   # macOS
   brew install --cask 1password-cli

   # Linux
   curl -sSfo op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v2.23.0/op_linux_amd64_v2.23.0.zip
   sudo unzip -od /usr/local/bin/ op.zip
   ```

3. **Authenticate 1Password CLI**
   ```bash
   eval $(op signin)
   ```

### Installation with Chezmoi

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize and apply dotfiles
chezmoi init --apply https://github.com/keitaoouchi/dotfiles_public.git

# Restart your shell
exec bash -l
```

### Testing Chezmoi Migration

Test the chezmoi setup in Docker:
```bash
# Copy chezmoi source to test directory
cp -r /tmp/chezmoi-migration/.local/share/chezmoi ./chezmoi-src

# Build and run test
docker build -f Dockerfile.chezmoi -t dotfiles-chezmoi-test .
docker run -it dotfiles-chezmoi-test

# Inside container, apply chezmoi
chezmoi init --apply --verbose

# Verify installation
ls -la ~/
cat ~/.gitconfig
which starship mise tmux
```

### Updating Dotfiles with Chezmoi

```bash
# Pull latest changes and apply
chezmoi update

# Or manually
cd ~/.local/share/chezmoi
git pull
chezmoi apply
```

### Making Changes

```bash
# Edit a config file
chezmoi edit ~/.bashrc

# Or edit directly and re-add
vim ~/.bashrc
chezmoi re-add ~/.bashrc

# Apply changes
chezmoi apply

# Commit and push
cd ~/.local/share/chezmoi
git add .
git commit -m "Update configuration"
git push
```