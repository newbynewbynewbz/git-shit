#!/bin/bash
# Git Shit: One-command setup for new cloners
# Run: bash scripts/setup-hooks.sh
#
# What this does:
#   1. Points git hooks to the repo's git-hooks/ directory (no copy needed)
#   2. Configures merge.ours driver (required for lock file merge strategy)
#   3. Optionally sets commit template and enables rerere
#   4. Makes all hooks executable

set -e

# Find repo root (works even if run from a subdirectory)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not a git repository. Run from inside a project."
  exit 1
fi

cd "$REPO_ROOT"

echo ""
echo "⚙️  Git Shit — Setting up your repo"
echo ""

# --- 1. Hook installation via core.hooksPath ---
# This points git to hooks inside the repo — they stay version-controlled
# and auto-update on git pull. No manual copy step needed.

HOOKS_DIR=""
if [ -d "scripts/git-hooks" ]; then
  HOOKS_DIR="scripts/git-hooks"
elif [ -d "git-hooks" ]; then
  HOOKS_DIR="git-hooks"
fi

if [ -n "$HOOKS_DIR" ]; then
  git config core.hooksPath "$HOOKS_DIR"
  chmod +x "$HOOKS_DIR"/* 2>/dev/null
  echo "  ✅ Hooks → $HOOKS_DIR/ (via core.hooksPath)"

  # List installed hooks
  for hook in "$HOOKS_DIR"/*; do
    if [ -f "$hook" ]; then
      HOOK_NAME=$(basename "$hook")
      echo "     ├── $HOOK_NAME"
    fi
  done
else
  # Fallback: check .git/hooks directly
  echo "  ⚠️  No hooks directory found (expected scripts/git-hooks/ or git-hooks/)"
  echo "     Checking .git/hooks/ instead..."

  MISSING=0
  for hook in pre-push pre-commit commit-msg prepare-commit-msg pre-rebase post-merge; do
    if [ -f ".git/hooks/$hook" ]; then
      chmod +x ".git/hooks/$hook"
      echo "     ├── $hook ✅"
    else
      echo "     ├── $hook ❌ missing"
      MISSING=$((MISSING + 1))
    fi
  done

  if [ "$MISSING" -gt 0 ]; then
    echo ""
    echo "  To install hooks, copy them from the git-shit template:"
    echo "    cp path/to/git-shit/template/git-hooks/* .git/hooks/"
    echo "    chmod +x .git/hooks/*"
  fi
fi

# --- 2. Configure merge.ours driver ---
# Required for merge=ours in .gitattributes (lock files keep your version on conflict)
# Without this, the merge=ours attribute is silently ignored.

CURRENT_OURS=$(git config --get merge.ours.driver 2>/dev/null || true)
if [ "$CURRENT_OURS" != "true" ]; then
  git config merge.ours.driver true
  echo "  ✅ merge.ours driver configured (lock files keep yours on conflict)"
else
  echo "  ✅ merge.ours driver already configured"
fi

# --- 3. Commit template ---
# If .gitmessage exists, set it as the commit template

if [ -f ".gitmessage" ]; then
  CURRENT_TEMPLATE=$(git config --get commit.template 2>/dev/null || true)
  if [ "$CURRENT_TEMPLATE" != ".gitmessage" ]; then
    git config commit.template .gitmessage
    echo "  ✅ Commit template → .gitmessage"
  else
    echo "  ✅ Commit template already set"
  fi
fi

# --- 4. Enable rerere (Reuse Recorded Resolution) ---
# Remembers how you resolved merge conflicts. Next time the same conflict
# appears, git auto-applies your previous resolution. Set and forget.

RERERE=$(git config --get rerere.enabled 2>/dev/null || true)
if [ "$RERERE" != "true" ]; then
  git config rerere.enabled true
  echo "  ✅ rerere enabled (conflict resolutions remembered)"
else
  echo "  ✅ rerere already enabled"
fi

echo ""
echo "Done. Test it:"
echo "  git commit -m \"test\"            → should be rejected (no prefix)"
echo "  git commit -m \"test: verify\"    → should pass"
echo ""
