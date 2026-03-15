#!/bin/bash
# Git Shit: One-command setup for new cloners
# Run: bash scripts/setup.sh
#
# What this does:
#   1. Points git hooks to the repo's git-hooks/ directory
#   2. Configures merge.ours driver (for lock file merge strategy)
#   3. Sets commit template and enables rerere
#   4. Applies recommended git config (local to this repo)
#   5. Makes all hooks executable

set -e

# Find repo root
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

  for hook in "$HOOKS_DIR"/*; do
    if [ -f "$hook" ]; then
      HOOK_NAME=$(basename "$hook")
      echo "     ├── $HOOK_NAME"
    fi
  done
else
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
CURRENT_OURS=$(git config --get merge.ours.driver 2>/dev/null || true)
if [ "$CURRENT_OURS" != "true" ]; then
  git config merge.ours.driver true
  echo "  ✅ merge.ours driver configured (lock files keep yours on conflict)"
else
  echo "  ✅ merge.ours driver already configured"
fi

# --- 3. Commit template ---
if [ -f ".gitmessage" ]; then
  CURRENT_TEMPLATE=$(git config --get commit.template 2>/dev/null || true)
  if [ "$CURRENT_TEMPLATE" != ".gitmessage" ]; then
    git config commit.template .gitmessage
    echo "  ✅ Commit template → .gitmessage"
  else
    echo "  ✅ Commit template already set"
  fi
fi

# --- 4. Enable rerere ---
RERERE=$(git config --get rerere.enabled 2>/dev/null || true)
if [ "$RERERE" != "true" ]; then
  git config rerere.enabled true
  echo "  ✅ rerere enabled (conflict resolutions remembered)"
else
  echo "  ✅ rerere already enabled"
fi

# --- 5. Recommended git config (repo-local) ---
echo ""
echo "  📐 Applying recommended git config..."

# Better conflict display — shows original code alongside both sides
CURRENT=$(git config --get merge.conflictstyle 2>/dev/null || true)
if [ "$CURRENT" != "zdiff3" ]; then
  git config merge.conflictstyle zdiff3
  echo "  ✅ merge.conflictstyle → zdiff3 (better conflict display)"
else
  echo "  ✅ merge.conflictstyle already set"
fi

# Auto-set upstream on first push
CURRENT=$(git config --get push.autoSetupRemote 2>/dev/null || true)
if [ "$CURRENT" != "true" ]; then
  git config push.autoSetupRemote true
  echo "  ✅ push.autoSetupRemote → true (no more 'set-upstream' errors)"
else
  echo "  ✅ push.autoSetupRemote already set"
fi

# Cleaner diffs
CURRENT=$(git config --get diff.algorithm 2>/dev/null || true)
if [ "$CURRENT" != "histogram" ]; then
  git config diff.algorithm histogram
  echo "  ✅ diff.algorithm → histogram (cleaner diffs)"
else
  echo "  ✅ diff.algorithm already set"
fi

# Show full diff in commit editor
CURRENT=$(git config --get commit.verbose 2>/dev/null || true)
if [ "$CURRENT" != "true" ]; then
  git config commit.verbose true
  echo "  ✅ commit.verbose → true (see diff in commit editor)"
else
  echo "  ✅ commit.verbose already set"
fi

# Highlight moved lines
CURRENT=$(git config --get diff.colorMoved 2>/dev/null || true)
if [ "$CURRENT" != "default" ]; then
  git config diff.colorMoved default
  echo "  ✅ diff.colorMoved → default (moved lines highlighted)"
else
  echo "  ✅ diff.colorMoved already set"
fi

# Sort branches by recency
CURRENT=$(git config --get branch.sort 2>/dev/null || true)
if [ "$CURRENT" != "-committerdate" ]; then
  git config branch.sort -committerdate
  echo "  ✅ branch.sort → -committerdate (recent branches first)"
else
  echo "  ✅ branch.sort already set"
fi

# Auto-clean stale remote branches
CURRENT=$(git config --get fetch.prune 2>/dev/null || true)
if [ "$CURRENT" != "true" ]; then
  git config fetch.prune true
  echo "  ✅ fetch.prune → true (stale remote branches auto-cleaned)"
else
  echo "  ✅ fetch.prune already set"
fi

# Auto-process fixup! commits during rebase
CURRENT=$(git config --get rebase.autosquash 2>/dev/null || true)
if [ "$CURRENT" != "true" ]; then
  git config rebase.autosquash true
  echo "  ✅ rebase.autosquash → true (fixup! commits auto-processed)"
else
  echo "  ✅ rebase.autosquash already set"
fi

# Auto-stash before rebase
CURRENT=$(git config --get rebase.autostash 2>/dev/null || true)
if [ "$CURRENT" != "true" ]; then
  git config rebase.autostash true
  echo "  ✅ rebase.autostash → true (auto-stash during rebase)"
else
  echo "  ✅ rebase.autostash already set"
fi

echo ""
echo "Done. Test it:"
echo "  git commit -m \"test\"            → should show conventional commit suggestion"
echo "  git commit -m \"test: verify\"    → should pass"
echo ""

# --- Level Up Further ---
echo "───────────────────────────────────────"
echo "  Level Up Further"
echo "───────────────────────────────────────"
echo "  lazygit     — terminal UI for git (the one tool everyone recommends)"
echo "  delta       — syntax-highlighted diffs in your terminal"
echo "  difftastic  — structural diffs that understand your language"
echo "  git-absorb  — auto-amend fixups into the right commits"
echo ""
echo "  Run 'bash scripts/git-shit-tools.sh' for install commands."
echo "───────────────────────────────────────"
echo ""
