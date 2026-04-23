#!/bin/bash
# Git Shit: Setup Health Check
# Audits your repo's git-shit configuration and reports what's configured,
# what's missing, and what could be improved.
# Usage: bash scripts/git-shit-status.sh

set -euo pipefail

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"

PASS=0
FAIL=0
WARN=0

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not inside a git repository."
  exit 1
}

check_pass() {
  echo -e "  ${GREEN}✓${RESET} $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo -e "  ${RED}✗${RESET} $1"
  FAIL=$((FAIL + 1))
}

check_warn() {
  echo -e "  ${YELLOW}~${RESET} $1"
  WARN=$((WARN + 1))
}

# --- Header ---
echo ""
echo -e "${BOLD}GIT SHIT STATUS — Health Check${RESET}"
echo -e "${DIM}Repository: $GIT_ROOT${RESET}"
echo ""

# --- Hooks ---
echo -e "${BOLD}HOOKS${RESET}"

HOOKS_DIR=""
HOOKS_PATH=$(git config --local core.hooksPath 2>/dev/null || echo "")
if [ -n "$HOOKS_PATH" ] && [ -d "$HOOKS_PATH" ]; then
  HOOKS_DIR="$HOOKS_PATH"
elif [ -n "$HOOKS_PATH" ] && [ -d "$GIT_ROOT/$HOOKS_PATH" ]; then
  HOOKS_DIR="$GIT_ROOT/$HOOKS_PATH"
elif [ -d "$GIT_ROOT/scripts/git-hooks" ]; then
  HOOKS_DIR="$GIT_ROOT/scripts/git-hooks"
elif [ -d "$GIT_ROOT/git-hooks" ]; then
  HOOKS_DIR="$GIT_ROOT/git-hooks"
elif [ -d "$GIT_ROOT/.git/hooks" ]; then
  HOOKS_DIR="$GIT_ROOT/.git/hooks"
fi

EXPECTED_HOOKS="pre-commit commit-msg pre-push prepare-commit-msg pre-rebase post-merge"
for hook in $EXPECTED_HOOKS; do
  if [ -n "$HOOKS_DIR" ] && [ -f "$HOOKS_DIR/$hook" ]; then
    if [ -x "$HOOKS_DIR/$hook" ]; then
      check_pass "$hook"
    else
      check_warn "$hook (exists but not executable)"
    fi
  else
    check_fail "$hook (missing)"
  fi
done
echo ""

# --- Config File ---
echo -e "${BOLD}CONFIG (.gitshitrc)${RESET}"

if [ -f "$GIT_ROOT/.gitshitrc" ]; then
  check_pass ".gitshitrc exists"
  if bash -n "$GIT_ROOT/.gitshitrc" 2>/dev/null; then
    check_pass ".gitshitrc is valid bash"
  else
    check_fail ".gitshitrc has syntax errors"
  fi

  # Source the config, then apply profile defaults to see what would actually run
  # shellcheck disable=SC1091
  . "$GIT_ROOT/.gitshitrc"
  if [ -f "$GIT_ROOT/scripts/lib/profile.sh" ]; then
    # shellcheck disable=SC1091
    . "$GIT_ROOT/scripts/lib/profile.sh"
  fi

  PROFILE_VALUE="${GIT_SHIT_PROFILE:-${PROFILE:-solo}}"
  case "$PROFILE_VALUE" in
    solo|team|strict) check_pass "GIT_SHIT_PROFILE=$PROFILE_VALUE" ;;
    *) check_warn "GIT_SHIT_PROFILE=$PROFILE_VALUE (unknown — falls back to solo)" ;;
  esac

  check_pass "TEACH_MODE=${TEACH_MODE:-off}"
  check_pass "COMMIT_MSG_MODE=${COMMIT_MSG_MODE:-off}"
  check_pass "BRANCH_NAMING_MODE=${BRANCH_NAMING_MODE:-off}"
  check_pass "SECRET_SCAN=${SECRET_SCAN:-on}"
  check_pass "PROTECTED_BRANCHES=${PROTECTED_BRANCHES:-main}"
  check_pass "LARGE_COMMIT_THRESHOLD=${LARGE_COMMIT_THRESHOLD:-500}"
else
  check_fail ".gitshitrc missing"
fi
echo ""

# --- Libs (v0.2+) ---
echo -e "${BOLD}LIBS (scripts/lib/)${RESET}"
for lib in profile.sh output.sh; do
  if [ -f "$GIT_ROOT/scripts/lib/$lib" ]; then
    check_pass "$lib"
  else
    check_warn "$lib missing (run: bash install.sh update)"
  fi
done
echo ""

# --- Template Files ---
echo -e "${BOLD}TEMPLATE FILES${RESET}"

if [ -f "$GIT_ROOT/.gitattributes" ]; then
  check_pass ".gitattributes"
else
  check_fail ".gitattributes (missing)"
fi

if [ -f "$GIT_ROOT/.gitmessage" ]; then
  check_pass ".gitmessage"
else
  check_fail ".gitmessage (missing)"
fi

PR_TEMPLATE=""
if [ -f "$GIT_ROOT/.github/pull_request_template.md" ]; then
  PR_TEMPLATE="yes"
  check_pass "PR template"
elif [ -f "$GIT_ROOT/.github/PULL_REQUEST_TEMPLATE.md" ]; then
  PR_TEMPLATE="yes"
  check_pass "PR template"
else
  check_warn "PR template (optional — .github/pull_request_template.md)"
fi
echo ""

# --- Git Config Settings ---
echo -e "${BOLD}GIT SETTINGS (repo-local)${RESET}"

check_git_config() {
  local key="$1"
  local expected="$2"
  local actual
  actual=$(git config --local "$key" 2>/dev/null || echo "")

  if [ -z "$actual" ]; then
    check_fail "$key (not set, recommended: $expected)"
  elif [ "$actual" = "$expected" ]; then
    check_pass "$key = $actual"
  else
    check_warn "$key = $actual (recommended: $expected)"
  fi
}

check_git_config "merge.conflictstyle" "zdiff3"
check_git_config "push.autoSetupRemote" "true"
check_git_config "diff.algorithm" "histogram"
check_git_config "commit.verbose" "true"
check_git_config "diff.colorMoved" "default"
check_git_config "branch.sort" "-committerdate"
check_git_config "fetch.prune" "true"
check_git_config "rebase.autosquash" "true"
check_git_config "rebase.autostash" "true"
check_git_config "rerere.enabled" "true"

# Check commit template
COMMIT_TEMPLATE=$(git config --local commit.template 2>/dev/null || echo "")
if [ -n "$COMMIT_TEMPLATE" ]; then
  check_pass "commit.template = $COMMIT_TEMPLATE"
else
  check_fail "commit.template (not set, recommended: .gitmessage)"
fi

# Check hooks path
if [ -n "$HOOKS_PATH" ]; then
  check_pass "core.hooksPath = $HOOKS_PATH"
else
  check_fail "core.hooksPath (not set)"
fi
echo ""

# --- Score ---
TOTAL=$((PASS + FAIL))
echo -e "${BOLD}SCORE: $PASS/$TOTAL checks passed${RESET}"
if [ "$WARN" -gt 0 ]; then
  echo -e "${DIM}  ($WARN warnings)${RESET}"
fi
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "  ${DIM}To fix missing settings, run:${RESET}"
  echo "    bash scripts/setup.sh"
  echo ""
fi
