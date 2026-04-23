#!/bin/bash
# Git Shit: One-command setup for new cloners
# Run: bash scripts/setup.sh
#
# Idempotent. Only prints the changes it actually applies.
# Flags:
#   --verbose      Print every check, not just changes
#   --fsmonitor    Also enable core.fsmonitor + core.untrackedCache (fast git status)

set -e

VERBOSE=0
WANT_FSMONITOR=0
while [ $# -gt 0 ]; do
  case "$1" in
    --verbose|-v) VERBOSE=1; shift ;;
    --fsmonitor)  WANT_FSMONITOR=1; shift ;;
    -h|--help)
      echo "Usage: bash scripts/setup.sh [--verbose] [--fsmonitor]"
      exit 0
      ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not a git repository. Run from inside a project."
  exit 1
fi
cd "$REPO_ROOT"

CHANGES=0
note() {
  CHANGES=$((CHANGES + 1))
  echo "  ✓ $1"
}
skip() {
  [ "$VERBOSE" = "1" ] && echo "  · $1 (already set)"
}

# --- 1. Hooks directory ---
HOOKS_DIR=""
[ -d "scripts/git-hooks" ] && HOOKS_DIR="scripts/git-hooks"
[ -z "$HOOKS_DIR" ] && [ -d "git-hooks" ] && HOOKS_DIR="git-hooks"

if [ -n "$HOOKS_DIR" ]; then
  CURRENT_HOOKS=$(git config --local core.hooksPath 2>/dev/null || echo "")
  if [ "$CURRENT_HOOKS" != "$HOOKS_DIR" ]; then
    git config core.hooksPath "$HOOKS_DIR"
    chmod +x "$HOOKS_DIR"/* 2>/dev/null || true
    note "core.hooksPath → $HOOKS_DIR/"
  else
    chmod +x "$HOOKS_DIR"/* 2>/dev/null || true
    skip "core.hooksPath"
  fi
fi

# --- 2. Ensure merge.ours driver (for lock file merges) ---
if [ "$(git config --get merge.ours.driver 2>/dev/null)" != "true" ]; then
  git config merge.ours.driver true
  note "merge.ours.driver = true"
else
  skip "merge.ours.driver"
fi

# --- 3. Commit template ---
if [ -f ".gitmessage" ]; then
  if [ "$(git config --get commit.template 2>/dev/null)" != ".gitmessage" ]; then
    git config commit.template .gitmessage
    note "commit.template → .gitmessage"
  else
    skip "commit.template"
  fi
fi

# --- 4. Recommended config ---
apply() {
  local key="$1" value="$2"
  if [ "$(git config --get "$key" 2>/dev/null)" != "$value" ]; then
    git config "$key" "$value"
    note "$key = $value"
  else
    skip "$key"
  fi
}

apply merge.conflictstyle zdiff3
apply push.autoSetupRemote true
apply diff.algorithm histogram
apply commit.verbose true
apply diff.colorMoved default
apply branch.sort -committerdate
apply fetch.prune true
apply rebase.autosquash true
apply rebase.autostash true
apply rerere.enabled true

# --- 5. Optional fsmonitor (git 2.37+, faster status on large repos) ---
if [ "$WANT_FSMONITOR" = "1" ]; then
  apply core.fsmonitor true
  apply core.untrackedCache true
fi

# --- Summary ---
if [ "$CHANGES" -eq 0 ]; then
  [ "$VERBOSE" = "1" ] && echo "  (nothing to change — setup already current)"
else
  echo ""
  echo "git-shit setup complete — $CHANGES change(s) applied."
fi
