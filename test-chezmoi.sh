#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_SRC="${1:-/tmp/chezmoi-migration/.local/share/chezmoi}"

echo "Testing chezmoi migration..."
echo "Chezmoi source: $CHEZMOI_SRC"
echo ""

# Check if chezmoi source exists
if [ ! -d "$CHEZMOI_SRC" ]; then
  echo "Error: Chezmoi source directory not found: $CHEZMOI_SRC"
  echo "Usage: $0 [chezmoi-source-dir]"
  exit 1
fi

# Copy chezmoi source to temporary location for Docker
TEMP_DIR=$(mktemp -d)
cp -r "$CHEZMOI_SRC" "$TEMP_DIR/chezmoi-src"

echo "Copied chezmoi source to: $TEMP_DIR/chezmoi-src"

# Build Docker image
echo ""
echo "Building Docker image..."
docker build -f "$SCRIPT_DIR/Dockerfile.chezmoi" -t dotfiles-chezmoi-test "$TEMP_DIR"

# Run Docker container
echo ""
echo "Starting Docker container..."
echo "================================"
echo "Run the following commands inside the container to test:"
echo "  chezmoi init --apply --verbose"
echo "  ls -la ~/"
echo "  cat ~/.gitconfig"
echo "  git config --list | grep user"
echo "  which starship mise tmux jq"
echo "================================"
echo ""

docker run -it --rm dotfiles-chezmoi-test

# Clean up
echo ""
echo "Cleaning up temporary directory: $TEMP_DIR"
rm -rf "$TEMP_DIR"

echo "Test complete!"
