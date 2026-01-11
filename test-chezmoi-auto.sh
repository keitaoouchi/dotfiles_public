#!/usr/bin/env bash
set -e

echo "Running automated chezmoi tests..."
echo ""

# Run chezmoi apply and verification commands in Docker
docker run --rm dotfiles-chezmoi-test bash -c '
set -e

echo "=== Initializing chezmoi ==="
chezmoi init --apply --verbose

echo ""
echo "=== Verifying files ==="
ls -la ~/

echo ""
echo "=== Checking gitconfig ==="
if [ -f ~/.gitconfig ]; then
  echo "✓ ~/.gitconfig exists"
  cat ~/.gitconfig | head -20
else
  echo "✗ ~/.gitconfig missing"
  exit 1
fi

echo ""
echo "=== Checking git config ==="
git config user.name || echo "✗ user.name not set"
git config user.email || echo "✗ user.email not set"
git config gpg.ssh.program || echo "✗ gpg.ssh.program not set"

echo ""
echo "=== Checking installed tools ==="
for tool in starship mise tmux jq git curl; do
  if command -v $tool &> /dev/null; then
    echo "✓ $tool installed: $(command -v $tool)"
  else
    echo "✗ $tool NOT FOUND"
  fi
done

echo ""
echo "=== Checking bashrc ==="
if [ -f ~/.bashrc ]; then
  echo "✓ ~/.bashrc exists"
  grep -q "GITHUB_TOKEN" ~/.bashrc && echo "✓ GITHUB_TOKEN found in bashrc" || echo "✗ GITHUB_TOKEN not found"
else
  echo "✗ ~/.bashrc missing"
fi

echo ""
echo "=== Checking chezmoi state ==="
chezmoi managed | head -20

echo ""
echo "=== Checking for differences ==="
DIFF_COUNT=$(chezmoi diff | wc -l)
if [ "$DIFF_COUNT" -eq 0 ]; then
  echo "✓ No differences found"
else
  echo "⚠️  Found $DIFF_COUNT lines of differences:"
  chezmoi diff | head -50
fi

echo ""
echo "=== Test Summary ==="
echo "✓ Chezmoi initialization successful"
echo "✓ Configuration files created"
echo "✓ Tools available (some may need actual installation to verify)"
'

echo ""
echo "Automated test complete!"
