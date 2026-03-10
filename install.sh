#!/bin/bash
# Git Shit: One-command installer
# Run from inside any git repo:
#   bash /path/to/git-shit/install.sh

set -e

# Resolve where this script lives (follows symlinks)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

# Validate: must be run inside a git repo
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not a git repository. cd into your project first."
  exit 1
}

# Validate: template directory must exist
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template/ not found at $TEMPLATE_DIR"
  echo "Run this script from the git-shit repo, not a copy."
  exit 1
fi

cd "$REPO_ROOT"

echo ""
echo "Installing git-shit into: $REPO_ROOT"
echo ""

# Copy hooks
mkdir -p scripts/git-hooks
cp "$TEMPLATE_DIR"/git-hooks/* scripts/git-hooks/
chmod +x scripts/git-hooks/*
echo "  Copied 6 hooks -> scripts/git-hooks/"

# Copy setup script
mkdir -p scripts
cp "$TEMPLATE_DIR/scripts/setup-hooks.sh" scripts/setup-hooks.sh
chmod +x scripts/setup-hooks.sh
echo "  Copied setup-hooks.sh -> scripts/"

# Copy config files
cp "$TEMPLATE_DIR/.gitattributes" .gitattributes
echo "  Copied .gitattributes"

cp "$TEMPLATE_DIR/.gitmessage" .gitmessage
echo "  Copied .gitmessage"

mkdir -p .github
cp "$TEMPLATE_DIR/.github/pull_request_template.md" .github/pull_request_template.md
echo "  Copied PR template -> .github/"

# Run setup to configure git
echo ""
bash scripts/setup-hooks.sh

echo "----------------------------------------"
echo "Done! Next steps:"
echo "  1. git add -A && git commit -m 'chore: add git-shit hooks and config'"
echo "  2. git push"
echo ""
echo "Your teammates just need to run after cloning:"
echo "  bash scripts/setup-hooks.sh"
echo ""
