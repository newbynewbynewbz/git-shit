#!/bin/bash
# Git Shit: One-command installer
# Run from inside any git repo:
#   bash /path/to/git-shit/install.sh          # first-time install
#   bash /path/to/git-shit/install.sh update   # refresh hooks/scripts only
#
# update mode:
#   - Refreshes scripts/git-hooks/* and scripts/*.sh with the latest versions
#   - Preserves .gitshitrc, .gitattributes, .gitmessage, PR template (may be customized)
#   - Still runs setup.sh (idempotent — reapplies git config)
#   - Errors out if no existing git-shit install is detected

set -e

# Parse mode from first argument
MODE="install"
case "${1:-}" in
  update)
    MODE="update"
    ;;
  ""|install)
    MODE="install"
    ;;
  -h|--help|help)
    echo "Usage: bash install.sh [install|update]"
    echo ""
    echo "  install   First-time install (default). Copies hooks, scripts, config."
    echo "  update    Refresh hooks and scripts only. Preserves config files."
    exit 0
    ;;
  *)
    echo "Error: unknown mode '$1'"
    echo "Usage: bash install.sh [install|update]"
    exit 1
    ;;
esac

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

# In update mode, require an existing git-shit install
if [ "$MODE" = "update" ]; then
  if [ ! -e ".gitshitrc" ] && [ ! -d "scripts/git-hooks" ]; then
    echo "Error: no existing git-shit install detected in $REPO_ROOT"
    echo ""
    echo "  Expected one of:"
    echo "    .gitshitrc"
    echo "    scripts/git-hooks/"
    echo ""
    echo "  For a first-time install, run without 'update':"
    echo "    bash $0"
    exit 1
  fi
  echo ""
  echo "Updating git-shit in: $REPO_ROOT"
  echo ""
else
  echo ""
  echo "Installing git-shit into: $REPO_ROOT"
  echo ""
fi

# Auto-detect default branch (only matters for fresh installs — update preserves existing .gitshitrc)
if [ "$MODE" = "install" ]; then
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' | tr -d '[:space:]')
  if [ -n "$DEFAULT_BRANCH" ] && [[ "$DEFAULT_BRANCH" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    PROTECTED_BRANCHES="$DEFAULT_BRANCH"
    echo "  Detected default branch: $DEFAULT_BRANCH"
  else
    PROTECTED_BRANCHES="main|master"
    echo "  No remote detected — protecting both main and master"
  fi
fi

# Copy hooks
mkdir -p scripts/git-hooks || { echo "Error: failed to create scripts/git-hooks/"; exit 1; }
cp "$TEMPLATE_DIR"/git-hooks/* scripts/git-hooks/ || { echo "Error: failed to copy hooks"; exit 1; }
chmod +x scripts/git-hooks/*
echo "  Copied 6 hooks -> scripts/git-hooks/"

# Copy setup scripts
mkdir -p scripts
cp "$TEMPLATE_DIR/scripts/setup.sh" scripts/setup.sh
chmod +x scripts/setup.sh
cp "$TEMPLATE_DIR/scripts/setup-hooks.sh" scripts/setup-hooks.sh
chmod +x scripts/setup-hooks.sh
cp "$TEMPLATE_DIR/scripts/git-shit-tools.sh" scripts/git-shit-tools.sh
chmod +x scripts/git-shit-tools.sh
cp "$TEMPLATE_DIR/scripts/git-shit-oops.sh" scripts/git-shit-oops.sh
chmod +x scripts/git-shit-oops.sh
cp "$TEMPLATE_DIR/scripts/git-shit-status.sh" scripts/git-shit-status.sh
chmod +x scripts/git-shit-status.sh
cp "$TEMPLATE_DIR/scripts/git-shit-workflow.sh" scripts/git-shit-workflow.sh
chmod +x scripts/git-shit-workflow.sh
echo "  Copied scripts -> scripts/"

# Copy config files (install mode only — update preserves user customizations)
if [ "$MODE" = "install" ]; then
  cp "$TEMPLATE_DIR/.gitattributes" .gitattributes
  echo "  Copied .gitattributes"

  cp "$TEMPLATE_DIR/.gitmessage" .gitmessage
  echo "  Copied .gitmessage"

  mkdir -p .github
  cp "$TEMPLATE_DIR/.github/pull_request_template.md" .github/pull_request_template.md
  echo "  Copied PR template -> .github/"

  # Copy .gitshitrc (only if not already present — don't overwrite team config)
  if [ ! -e ".gitshitrc" ]; then
    sed "s|^PROTECTED_BRANCHES=.*|PROTECTED_BRANCHES=$PROTECTED_BRANCHES|" \
      "$TEMPLATE_DIR/.gitshitrc" > .gitshitrc
    echo "  Created .gitshitrc (PROTECTED_BRANCHES=$PROTECTED_BRANCHES)"
  else
    echo "  Skipped .gitshitrc (already exists — keeping team config)"
  fi
else
  echo "  Preserved: .gitshitrc, .gitattributes, .gitmessage, PR template"

  # Migrate v1 .gitshitrc: append any missing v2 keys without modifying existing ones
  if [ -f ".gitshitrc" ]; then
    MIGRATION_BUFFER=$(mktemp) || MIGRATION_BUFFER=""
    if [ -n "$MIGRATION_BUFFER" ]; then
      trap 'rm -f "$MIGRATION_BUFFER"' EXIT
      ADDED_KEYS=""

      if ! grep -q "^TEACH_MODE=" .gitshitrc; then
        echo "TEACH_MODE=on                  # on | off (educational hints in hook output)" >> "$MIGRATION_BUFFER"
        ADDED_KEYS="$ADDED_KEYS TEACH_MODE"
      fi
      if ! grep -q "^BRANCH_PATTERN=" .gitshitrc; then
        echo 'BRANCH_PATTERN="^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert|research)/.+"' >> "$MIGRATION_BUFFER"
        ADDED_KEYS="$ADDED_KEYS BRANCH_PATTERN"
      fi
      if ! grep -q "^BRANCH_NAMING_MODE=" .gitshitrc; then
        echo "BRANCH_NAMING_MODE=warn        # strict | warn | off" >> "$MIGRATION_BUFFER"
        ADDED_KEYS="$ADDED_KEYS BRANCH_NAMING_MODE"
      fi

      if [ -s "$MIGRATION_BUFFER" ]; then
        {
          echo ""
          echo "# v2 migration — keys added by install.sh update"
          cat "$MIGRATION_BUFFER"
        } >> .gitshitrc
        # Validate the result before celebrating
        if bash -n .gitshitrc 2>/dev/null; then
          echo "  Migrated .gitshitrc: added$ADDED_KEYS"
        else
          echo "  ⚠️  Migration wrote invalid bash to .gitshitrc — review and fix manually"
        fi
      else
        echo "  .gitshitrc already has all v2 keys"
      fi

      rm -f "$MIGRATION_BUFFER"
      trap - EXIT
    fi
  fi
fi

# Run setup to configure git
echo ""
bash scripts/setup.sh

echo "----------------------------------------"
if [ "$MODE" = "update" ]; then
  echo "Updated! Changed files:"
  echo "  scripts/git-hooks/*    (refreshed)"
  echo "  scripts/*.sh           (refreshed)"
  echo ""
  echo "Review and commit:"
  echo "  git diff scripts/"
  echo "  git add scripts/ && git commit -m 'chore: update git-shit hooks'"
  echo ""
else
  echo "Done! Next steps:"
  echo "  1. git add -A && git commit -m 'chore: add git-shit hooks and config'"
  echo "  2. git push"
  echo ""
  echo "Your teammates just need to run after cloning:"
  echo "  bash scripts/setup.sh"
  echo ""
  echo "Explore more:"
  echo "  bash scripts/git-shit-oops.sh       # quick fixes for common mistakes"
  echo "  bash scripts/git-shit-status.sh     # audit your git setup"
  echo "  bash scripts/git-shit-workflow.sh   # find the right branching strategy"
  echo "  bash scripts/git-shit-tools.sh      # recommended git tools"
  echo ""
fi
