#!/bin/bash
# Git Shit: One-command installer
# Run from inside any git repo:
#   bash /path/to/git-shit/install.sh                     # first-time install (solo profile)
#   bash /path/to/git-shit/install.sh --profile team      # install with team profile
#   bash /path/to/git-shit/install.sh update              # refresh hooks/libs/scripts only
#   bash /path/to/git-shit/install.sh update --profile team   # refresh + switch profile
#
# update mode:
#   - Refreshes scripts/git-hooks/*, scripts/lib/*, scripts/*.sh
#   - Preserves .gitshitrc, .gitattributes, .gitmessage, PR template
#   - With --profile, rewrites the GIT_SHIT_PROFILE line in .gitshitrc
#   - Still runs setup.sh (idempotent)

set -e

MODE="install"
PROFILE=""

# Parse args: first positional = mode, optional --profile <value>
while [ $# -gt 0 ]; do
  case "$1" in
    update|install)
      MODE="$1"
      shift
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --profile=*)
      PROFILE="${1#--profile=}"
      shift
      ;;
    -h|--help|help)
      cat <<EOF
Usage: bash install.sh [install|update] [--profile solo|team|strict]

  install   First-time install (default). Copies hooks, libs, scripts, config.
  update    Refresh hooks/libs/scripts only. Preserves config files.

  --profile solo     (default) quiet, velocity — no CC enforcement, teach off
  --profile team     conventional commits warn, branch naming warn, teach on
  --profile strict   CC strict, branch naming strict, main+develop protected
EOF
      exit 0
      ;;
    "")
      shift
      ;;
    *)
      echo "Error: unknown argument '$1'"
      echo "Usage: bash install.sh [install|update] [--profile solo|team|strict]"
      exit 1
      ;;
  esac
done

# Default profile for fresh installs
[ -z "$PROFILE" ] && [ "$MODE" = "install" ] && PROFILE="solo"

# Validate profile if one was resolved
if [ -n "$PROFILE" ]; then
  case "$PROFILE" in
    solo|team|strict) ;;
    *)
      echo "Error: unknown profile '$PROFILE'. Valid: solo, team, strict."
      exit 1
      ;;
  esac
fi

# Resolve where this script lives (follows symlinks)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not a git repository. cd into your project first."
  exit 1
}

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template/ not found at $TEMPLATE_DIR"
  echo "Run this script from the git-shit repo, not a copy."
  exit 1
fi

cd "$REPO_ROOT"

if [ "$MODE" = "update" ]; then
  if [ ! -e ".gitshitrc" ] && [ ! -d "scripts/git-hooks" ]; then
    echo "Error: no existing git-shit install detected in $REPO_ROOT"
    echo "  For a first-time install: bash $0"
    exit 1
  fi
  echo ""
  echo "Updating git-shit in: $REPO_ROOT"
  [ -n "$PROFILE" ] && echo "  Profile override: $PROFILE"
  echo ""
else
  echo ""
  echo "Installing git-shit into: $REPO_ROOT"
  echo "  Profile: $PROFILE"
  echo ""
fi

# Auto-detect default branch (only matters for fresh installs)
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

# --- Copy hooks ---
mkdir -p scripts/git-hooks
cp "$TEMPLATE_DIR"/git-hooks/* scripts/git-hooks/
chmod +x scripts/git-hooks/*
echo "  Copied 6 hooks -> scripts/git-hooks/"

# --- Copy libs (new in v0.2) ---
mkdir -p scripts/lib
cp "$TEMPLATE_DIR"/scripts/lib/* scripts/lib/
echo "  Copied lib helpers -> scripts/lib/"

# --- Copy setup scripts ---
mkdir -p scripts
for script in setup.sh setup-hooks.sh git-shit-tools.sh git-shit-oops.sh git-shit-status.sh git-shit-workflow.sh; do
  if [ -f "$TEMPLATE_DIR/scripts/$script" ]; then
    cp "$TEMPLATE_DIR/scripts/$script" "scripts/$script"
    chmod +x "scripts/$script"
  fi
done
echo "  Copied scripts -> scripts/"

# --- Config files ---
if [ "$MODE" = "install" ]; then
  cp "$TEMPLATE_DIR/.gitattributes" .gitattributes
  echo "  Copied .gitattributes"

  cp "$TEMPLATE_DIR/.gitmessage" .gitmessage
  echo "  Copied .gitmessage"

  mkdir -p .github
  cp "$TEMPLATE_DIR/.github/pull_request_template.md" .github/pull_request_template.md
  echo "  Copied PR template -> .github/"

  if [ ! -e ".gitshitrc" ]; then
    # Substitute profile + protected branches into the template.
    # Use @ as sed delimiter since PROTECTED_BRANCHES can contain pipes (main|master).
    # Write via temp file so a sed failure doesn't leave an empty .gitshitrc.
    TMP_RC=$(mktemp)
    trap 'rm -f "$TMP_RC"' EXIT
    sed -e "s@^GIT_SHIT_PROFILE=.*@GIT_SHIT_PROFILE=$PROFILE@" \
        -e "s@^# PROTECTED_BRANCHES=.*@PROTECTED_BRANCHES=\"$PROTECTED_BRANCHES\"@" \
        "$TEMPLATE_DIR/.gitshitrc" > "$TMP_RC"
    mv "$TMP_RC" .gitshitrc
    trap - EXIT
    echo "  Created .gitshitrc (profile=$PROFILE, protected=$PROTECTED_BRANCHES)"
  else
    echo "  Skipped .gitshitrc (already exists — keeping existing config)"
  fi
else
  # Update mode: handle optional profile override
  if [ -n "$PROFILE" ] && [ -f ".gitshitrc" ]; then
    if grep -q "^GIT_SHIT_PROFILE=" .gitshitrc; then
      # Replace existing line
      sed -i.gsbak "s|^GIT_SHIT_PROFILE=.*|GIT_SHIT_PROFILE=$PROFILE|" .gitshitrc
      rm -f .gitshitrc.gsbak
      echo "  Updated .gitshitrc: GIT_SHIT_PROFILE=$PROFILE"
    else
      # v1 config predates profiles — prepend the line
      {
        echo "# v0.2 migration — profile added"
        echo "GIT_SHIT_PROFILE=$PROFILE"
        echo ""
        cat .gitshitrc
      } > .gitshitrc.gsnew && mv .gitshitrc.gsnew .gitshitrc
      echo "  Added GIT_SHIT_PROFILE=$PROFILE to .gitshitrc"
    fi
  else
    echo "  Preserved: .gitshitrc, .gitattributes, .gitmessage, PR template"
  fi

  # v1 migration — append any missing v2 keys
  if [ -f ".gitshitrc" ]; then
    MIGRATION_BUFFER=$(mktemp) || MIGRATION_BUFFER=""
    if [ -n "$MIGRATION_BUFFER" ]; then
      trap 'rm -f "$MIGRATION_BUFFER"' EXIT
      ADDED_KEYS=""

      if ! grep -q "^GIT_SHIT_PROFILE=" .gitshitrc && ! grep -q "^PROFILE=" .gitshitrc; then
        # Predates v0.2 profiles entirely — no explicit profile; opt them into 'team'
        # to preserve v1 behavior (TEACH=on, CC=warn, BRANCH=warn) unless --profile was given
        DEFAULT_MIGRATE_PROFILE="${PROFILE:-team}"
        echo "GIT_SHIT_PROFILE=$DEFAULT_MIGRATE_PROFILE" >> "$MIGRATION_BUFFER"
        ADDED_KEYS="$ADDED_KEYS GIT_SHIT_PROFILE=$DEFAULT_MIGRATE_PROFILE"
      fi

      if [ -s "$MIGRATION_BUFFER" ]; then
        {
          echo ""
          echo "# v0.2 migration"
          cat "$MIGRATION_BUFFER"
        } >> .gitshitrc
        if bash -n .gitshitrc 2>/dev/null; then
          echo "  Migrated .gitshitrc: added$ADDED_KEYS"
        else
          echo "  ⚠️  Migration wrote invalid bash to .gitshitrc — review and fix manually"
        fi
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
  echo "Updated. Changed files:"
  echo "  scripts/git-hooks/*    (refreshed)"
  echo "  scripts/lib/*          (refreshed)"
  echo "  scripts/*.sh           (refreshed)"
  echo ""
  echo "Review and commit:"
  echo "  git diff scripts/"
  echo "  git add scripts/ && git commit -m 'chore: update git-shit to v0.2'"
  echo ""
else
  echo "Done. Next steps:"
  echo "  git add -A && git commit -m 'chore: add git-shit hooks and config'"
  echo ""
  echo "Teammates just need to run after cloning:"
  echo "  bash scripts/setup.sh"
  echo ""
fi
