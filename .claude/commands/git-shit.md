---
name: git-shit
description: Pimp out any repo's git setup — hooks, conventional commits, PR workflow, branch protection, templates. Drop in and go.
argument: "[path|new <name>|audit]"
model-hint: sonnet
---

# Git Shit — Level Up Your Git Game

Drop this into any repo and instantly get: commit message enforcement, push protection, PR templates, gitattributes, branch naming, secret scanning, recommended git config, and a setup script for the whole team.

## Arguments

| Input | Action |
|-------|--------|
| *(empty)* | Install into current repo |
| `<path>` | Install into repo at specified path |
| `new <name>` | Create new dir + `git init` + install |
| `audit` | Audit existing git setup — report what's missing |

## Step 1: Detect Context

```
- Is this a git repo? (git rev-parse --git-dir)
- Existing hooks? (check .git/hooks/ AND core.hooksPath config)
- Existing .gitattributes?
- Existing .gitignore?
- Existing .gitmessage?
- Existing PR template?
- Remote origin? (GitHub, GitLab, Bitbucket?)
- Is merge.ours.driver configured? (git config --get merge.ours.driver)
- Is rerere enabled? (git config --get rerere.enabled)
- Is commit.template set? (git config --get commit.template)
- Existing .gitshitrc? (check repo root)
- Recommended git config applied? (check merge.conflictstyle, push.autoSetupRemote, diff.algorithm, etc.)
```

If `new <name>`: create directory, `cd`, `git init`. After `git init`, create `.gitshitrc` with auto-detected defaults (same logic as `install.sh`).
If `audit`: skip to Step 7 (audit only, no writes).
If hooks already exist, use AskUserQuestion: "You have existing git hooks. Overwrite or skip?"

## Step 2: Ask Setup Questions

Use AskUserQuestion:

**Question 1 — Primary language:**
- TypeScript/JavaScript (Recommended)
- Python
- Go
- Rust
- Other

**Question 2 — Package manager (for lock file handling):**
- npm
- bun
- yarn
- pnpm
- pip/uv
- cargo
- go modules
- Other

**Question 3 — Default branch:**
Auto-detected from `git symbolic-ref refs/remotes/origin/HEAD`. If no remote, defaults to protecting both `main` and `master`. Only ask if auto-detection fails AND a remote exists.

Store as `$LANG`, `$PKG_MGR`.

## Step 3: Install Git Hooks

Write all 6 hooks to `scripts/git-hooks/` and `chmod +x` each one. Then set `core.hooksPath`:

```bash
git config core.hooksPath scripts/git-hooks
```

This keeps hooks version-controlled and auto-updates them on `git pull`. No copy step needed for teammates — just `bash scripts/setup.sh`.

### `scripts/git-hooks/pre-push`

Blocks direct pushes to protected branches (config-driven). Forces PR workflow.

```bash
#!/bin/bash
# Git Shit: Pre-push hook
# Blocks direct pushes to protected branches — forces PR workflow
# Bypass: git push --no-verify (emergencies only)

# --- Config loader ---
_git_shit_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -f "$_git_shit_root/.gitshitrc" ] && . "$_git_shit_root/.gitshitrc"

PROTECTED_BRANCHES="${GIT_SHIT_PROTECTED_BRANCHES:-${PROTECTED_BRANCHES:-main}}"

while read local_ref local_sha remote_ref remote_sha; do
  IFS='|' read -ra BRANCHES <<< "$PROTECTED_BRANCHES"
  for PROTECTED in "${BRANCHES[@]}"; do
    if [ "$remote_ref" = "refs/heads/$PROTECTED" ]; then
      echo ""
      echo "🛑 Direct push to $PROTECTED blocked"
      echo ""
      echo "  Use the PR workflow instead:"
      echo "    1. git checkout -b feature/my-change"
      echo "    2. git push -u origin feature/my-change"
      echo "    3. gh pr create --fill"
      echo "    4. gh pr merge --squash --delete-branch"
      echo ""
      echo "  Emergency bypass: git push --no-verify"
      echo ""
      exit 1
    fi
  done
done

exit 0
```

### `scripts/git-hooks/pre-commit`

Secret scanning (hard block) + non-blocking warning when staged changes are large.

```bash
#!/bin/bash
# Git Shit: Pre-commit hook
# 1. Secret scanning (hard block when on)
# 2. Large commit warning (non-blocking)
# 3. Whitespace check (non-blocking)

# --- Config loader ---
_git_shit_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -f "$_git_shit_root/.gitshitrc" ] && . "$_git_shit_root/.gitshitrc"

SECRET_SCAN="${GIT_SHIT_SECRET_SCAN:-${SECRET_SCAN:-on}}"
LARGE_COMMIT_THRESHOLD="${GIT_SHIT_LARGE_COMMIT_THRESHOLD:-${LARGE_COMMIT_THRESHOLD:-200}}"

# --- 1. Secret scanning ---
if [ "$SECRET_SCAN" = "on" ]; then
  SECRETS_FOUND=0

  # Check staged filenames (basename only)
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    base=$(basename "$file")
    case "$base" in
      .env|.env.*) ;;
      *.pem|*.key) ;;
      id_rsa|id_ed25519) ;;
      *) continue ;;
    esac
    if [ "$SECRETS_FOUND" -eq 0 ]; then
      echo ""
      echo "🛑 Possible secrets detected in staged files:"
      echo ""
    fi
    echo "  File: $file"
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
  done < <(git diff --cached --name-only --diff-filter=ACM)

  # Scan staged file contents for secret patterns
  PATTERNS=(
    'AKIA[0-9A-Z]{16}'
    '-----BEGIN.*PRIVATE KEY-----'
    'sk-[a-zA-Z0-9]{20,}'
    'ghp_[a-zA-Z0-9]{36}'
  )
  PATTERN_NAMES=(
    "AWS access key"
    "Private key"
    "API secret key (sk-...)"
    "GitHub personal access token"
  )

  for i in "${!PATTERNS[@]}"; do
    MATCHES=$(git diff --cached -U0 --diff-filter=ACM 2>/dev/null | grep -nE "^\+" | grep -E "${PATTERNS[$i]}" 2>/dev/null)
    if [ -n "$MATCHES" ]; then
      if [ "$SECRETS_FOUND" -eq 0 ]; then
        echo ""
        echo "🛑 Possible secrets detected in staged files:"
        echo ""
      fi
      echo "  Pattern: ${PATTERN_NAMES[$i]}"
      echo "$MATCHES" | head -3 | while read -r line; do
        echo "    $line"
      done
      MATCH_COUNT=$(echo "$MATCHES" | wc -l | tr -d ' ')
      if [ "$MATCH_COUNT" -gt 3 ]; then
        echo "    ... and $((MATCH_COUNT - 3)) more"
      fi
      SECRETS_FOUND=$((SECRETS_FOUND + 1))
    fi
  done

  if [ "$SECRETS_FOUND" -gt 0 ]; then
    echo ""
    echo "  To bypass for test fixtures with fake keys:"
    echo "    GIT_SHIT_SECRET_SCAN=off git commit -m \"your message\""
    echo ""
    echo "  For comprehensive scanning, check out: https://github.com/gitleaks/gitleaks"
    echo ""
    exit 1
  fi
fi

# --- 2. Large commit warning (non-blocking) ---
INSERTIONS=$(git diff --cached --numstat | awk '{sum+=$1} END{print sum+0}')

if [ "$INSERTIONS" -gt "$LARGE_COMMIT_THRESHOLD" ]; then
  echo ""
  echo "⚠️  Commit size warning: $INSERTIONS insertions (threshold: $LARGE_COMMIT_THRESHOLD)"
  echo ""
  echo "  Staged files:"
  git diff --cached --stat | tail -1
  echo ""
  echo "  Consider splitting into smaller atomic commits."
  echo "  Ask: 'Is this truly ONE logical change?'"
  echo ""
  echo "  Tip: use 'git add -p' to stage changes hunk-by-hunk"
  echo "       and split this into multiple focused commits."
  echo ""
fi

# --- 3. Non-blocking whitespace check ---
if ! git diff --cached --check > /dev/null 2>&1; then
  echo "⚠️  Whitespace issues detected (trailing spaces, mixed tabs)"
  echo "  Run: git diff --cached --check    to see details"
  echo ""
fi

exit 0
```

### `scripts/git-hooks/commit-msg`

Enforces conventional commit prefixes. Configurable: strict (block), warn (suggest), or off (skip).

```bash
#!/bin/bash
# Git Shit: Commit-msg hook
# Enforces conventional commit prefixes
# Modes: strict (block) | warn (suggest) | off (skip)

# --- Config loader ---
_git_shit_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -f "$_git_shit_root/.gitshitrc" ] && . "$_git_shit_root/.gitshitrc"

COMMIT_MSG_MODE="${GIT_SHIT_COMMIT_MSG:-${COMMIT_MSG_MODE:-warn}}"

# Skip entirely if turned off
if [ "$COMMIT_MSG_MODE" = "off" ]; then
  exit 0
fi

MSG_FILE="$1"

if [ -z "$MSG_FILE" ] || [ ! -f "$MSG_FILE" ]; then
  exit 0
fi

MSG=$(head -1 "$MSG_FILE")

# Allow merge commits
if echo "$MSG" | grep -qE '^Merge '; then
  exit 0
fi

# Allow squash merge commits from GitHub
if echo "$MSG" | grep -qE '^\S+.*\(#[0-9]+\)$'; then
  exit 0
fi

# Allow fixup/squash commits
if echo "$MSG" | grep -qE '^(fixup|squash)! '; then
  exit 0
fi

# Check for conventional commit prefix
if echo "$MSG" | grep -qE '^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\([a-zA-Z0-9_-]+\))?!?: .+'; then
  exit 0
fi

# Message doesn't conform — behavior depends on mode
echo ""
if [ "$COMMIT_MSG_MODE" = "strict" ]; then
  echo "🛑 Commit message rejected — missing conventional prefix"
else
  echo "💡 Commit message suggestion — consider using a conventional prefix"
fi
echo ""
echo "  Your message:  $MSG"
echo ""
echo "  Required format: <type>(<scope>): <description>"
echo ""
echo "  Types: feat fix refactor docs test chore style perf ci build revert"
echo "  Scope: optional — e.g., feat(auth): or fix(api):"
echo ""
echo "  Examples:"
echo "    feat: add user authentication flow"
echo "    fix(api): prevent crash on empty response"
echo "    docs: update contributing guide"
echo ""

if [ "$COMMIT_MSG_MODE" = "strict" ]; then
  exit 1
fi

exit 0
```

### `scripts/git-hooks/prepare-commit-msg`

Pre-fills conventional commit prefix from branch name. Fires before the editor opens.

```bash
#!/bin/bash
# Git Shit: prepare-commit-msg hook
# Pre-fills conventional commit prefix from branch name
# Fires before the editor opens — shows correct format before you type

# --- Config loader ---
_git_shit_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -f "$_git_shit_root/.gitshitrc" ] && . "$_git_shit_root/.gitshitrc"

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"

# Only auto-fill for new commits (not merges, amends, squashes, etc.)
if [ -n "$COMMIT_SOURCE" ]; then
  exit 0
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

# Extract type from branch name: feat/add-login -> feat
TYPE=$(echo "$BRANCH" | sed -n 's|^\(feat\|fix\|refactor\|docs\|test\|chore\|style\|perf\|ci\|build\|revert\)/.*|\1|p')

# Extract scope from branch name: feat/auth/add-login -> feat(auth)
SCOPE=$(echo "$BRANCH" | sed -n 's|^\(feat\|fix\|refactor\|docs\|test\|chore\|style\|perf\|ci\|build\|revert\)/\([a-zA-Z0-9_-]*\)/.*|\2|p')

# Only pre-fill if the first line is empty (not already filled by template or -m)
FIRST_LINE=$(head -1 "$COMMIT_MSG_FILE")
if [ -n "$TYPE" ] && [ -z "$FIRST_LINE" ]; then
  if [ -n "$SCOPE" ]; then
    PREFIX="$TYPE($SCOPE): "
  else
    PREFIX="$TYPE: "
  fi
  # Prepend prefix to the commit message file
  TEMP=$(mktemp) || exit 0
  echo "$PREFIX" > "$TEMP"
  # Append original content (template comments, etc.)
  tail -n +2 "$COMMIT_MSG_FILE" >> "$TEMP"
  mv "$TEMP" "$COMMIT_MSG_FILE"
fi

exit 0
```

### `scripts/git-hooks/pre-rebase`

Blocks rebasing commits that have already been pushed. Prevents accidental history rewriting.

```bash
#!/bin/bash
# Git Shit: pre-rebase hook
# Prevents rebasing commits that have already been pushed to a remote
# Protects shared history from accidental rewriting

# --- Config loader ---
_git_shit_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -f "$_git_shit_root/.gitshitrc" ] && . "$_git_shit_root/.gitshitrc"

UPSTREAM="$1"
BRANCH="$2"

# If no branch specified, we're rebasing the current branch
if [ -z "$BRANCH" ]; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
fi

# Skip if we can't determine the branch (detached HEAD)
if [ -z "$BRANCH" ]; then
  exit 0
fi

# Check if this branch has a remote tracking branch
REMOTE_REF=$(git rev-parse --verify "origin/$BRANCH" 2>/dev/null)
if [ -z "$REMOTE_REF" ]; then
  # No remote tracking — local only, safe to rebase
  exit 0
fi

# Check if the local branch has commits that exist on the remote
# If local and remote point to the same commit, rebasing is fine
# (we're rebasing on top of remote changes)
LOCAL_REF=$(git rev-parse "$BRANCH" 2>/dev/null)
if [ "$LOCAL_REF" = "$REMOTE_REF" ]; then
  exit 0
fi

# Check if there are commits on the remote that would be rewritten
PUSHED_COMMITS=$(git log --oneline "origin/$BRANCH..$BRANCH" 2>/dev/null | wc -l | tr -d ' ')

if [ "$PUSHED_COMMITS" -gt 0 ]; then
  # The local branch is ahead — those unpushed commits are safe to rebase
  # But check if the remote has diverged (someone else pushed)
  REMOTE_ONLY=$(git log --oneline "$BRANCH..origin/$BRANCH" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$REMOTE_ONLY" -gt 0 ]; then
    echo ""
    echo "⚠️  Rebase warning: origin/$BRANCH has diverged"
    echo ""
    echo "  Your branch and the remote have both changed."
    echo "  Rebasing may rewrite commits others have seen."
    echo ""
    echo "  Consider: git pull --rebase origin $BRANCH"
    echo "  Or merge: git merge origin/$BRANCH"
    echo ""
    # Warning only — don't block (user may know what they're doing)
  fi
  exit 0
fi

# The remote is ahead or equal — check if we'd rewrite pushed commits
WOULD_REWRITE=$(git log --oneline "$UPSTREAM..$BRANCH" 2>/dev/null)
REWRITE_COUNT=$(echo "$WOULD_REWRITE" | grep -c '^' 2>/dev/null)

# Check if any of those commits exist on the remote
SHARED_COUNT=0
while IFS= read -r line; do
  SHA=$(echo "$line" | awk '{print $1}')
  if git branch -r --contains "$SHA" 2>/dev/null | grep -q "origin/$BRANCH"; then
    SHARED_COUNT=$((SHARED_COUNT + 1))
  fi
done <<< "$WOULD_REWRITE"

if [ "$SHARED_COUNT" -gt 0 ]; then
  echo ""
  echo "🛑 Rebase blocked — $SHARED_COUNT commit(s) already pushed to origin/$BRANCH"
  echo ""
  echo "  Rebasing pushed commits rewrites shared history."
  echo "  This forces teammates to deal with diverged branches."
  echo ""
  echo "  Instead:"
  echo "    git merge $UPSTREAM          # merge instead of rebase"
  echo "    git pull --no-rebase         # pull with merge"
  echo ""
  echo "  If you're sure (solo branch, force-push planned):"
  echo "    git rebase $UPSTREAM --no-verify"
  echo ""
  exit 1
fi

exit 0
```

### `scripts/git-hooks/post-merge`

Reminds you to install dependencies when lock files change after pull/merge.

```bash
#!/bin/bash
# Git Shit: post-merge hook
# Reminds you to install dependencies when lock files change after pull/merge

# --- Config loader ---
_git_shit_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -f "$_git_shit_root/.gitshitrc" ] && . "$_git_shit_root/.gitshitrc"

CHANGED=$(git diff-tree -r --name-only ORIG_HEAD HEAD 2>/dev/null)

if [ -z "$CHANGED" ]; then
  exit 0
fi

NEEDS_INSTALL=""

# Check each package manager's lock file
if echo "$CHANGED" | grep -q "package-lock.json"; then
  NEEDS_INSTALL="npm install"
elif echo "$CHANGED" | grep -q "yarn.lock"; then
  NEEDS_INSTALL="yarn install"
elif echo "$CHANGED" | grep -q "pnpm-lock.yaml"; then
  NEEDS_INSTALL="pnpm install"
elif echo "$CHANGED" | grep -q "bun.lockb"; then
  NEEDS_INSTALL="bun install"
elif echo "$CHANGED" | grep -q "Cargo.lock"; then
  NEEDS_INSTALL="cargo build"
elif echo "$CHANGED" | grep -q "requirements.txt\|Pipfile.lock\|poetry.lock\|uv.lock"; then
  NEEDS_INSTALL="pip install -r requirements.txt"
elif echo "$CHANGED" | grep -q "go.sum"; then
  NEEDS_INSTALL="go mod download"
elif echo "$CHANGED" | grep -q "Gemfile.lock"; then
  NEEDS_INSTALL="bundle install"
fi

if [ -n "$NEEDS_INSTALL" ]; then
  echo ""
  echo "📦 Dependencies changed — run: $NEEDS_INSTALL"
  echo ""
fi

exit 0
```

## Step 4: Create .gitattributes

Adapt based on `$LANG` and `$PKG_MGR`:

```
# Images — binary, no text diffs
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.webp binary
*.ico binary
*.svg text

# Fonts
*.ttf binary
*.otf binary
*.woff binary
*.woff2 binary

# Lock files — don't manually merge, keep ours on conflict
# Requires: git config merge.ours.driver true (setup.sh handles this)
$LOCKFILE_ENTRY

# Auto-normalize line endings
* text=auto

# Diff drivers for binary files (uncomment + install tool for meaningful diffs)
# *.png diff=exif        # brew install exiftool; git config diff.exif.textconv exiftool
# *.jpg diff=exif        # Shows EXIF metadata changes instead of "binary files differ"
# *.docx diff=word       # pip install docx2txt; git config diff.word.textconv docx2txt

# Exclude dev-only files from git archive / release tarballs
.github/ export-ignore
scripts/ export-ignore
.claude/ export-ignore
```

Lock file entries by package manager:
- npm: `package-lock.json -diff merge=ours`
- bun: `bun.lockb binary`
- yarn: `yarn.lock -diff merge=ours`
- pnpm: `pnpm-lock.yaml -diff merge=ours`
- pip: `requirements.txt -diff merge=ours`
- cargo: `Cargo.lock -diff merge=ours`
- go: `go.sum -diff merge=ours`
- ruby: `Gemfile.lock -diff merge=ours`

Add language-specific entries:
- Go: `*.pb.go linguist-generated=true` (protobuf)
- Rust: `*.rlib binary`
- Python: `*.pyc binary`, `*.pyo binary`

## Step 5: Create PR Template

If remote is GitHub, write `.github/pull_request_template.md`:

```markdown
## What

<!-- One sentence: what does this PR do? -->

## Why

<!-- Why is this change needed? Link to issue if applicable. -->

## How

<!-- Brief description of the approach. -->

## Test Plan

- [ ] Tests pass locally
- [ ] Manual testing done
- [ ] No console.log / debug statements left

## Screenshots

<!-- If UI change, add before/after screenshots. Delete this section if N/A. -->
```

If remote is GitLab, write `.gitlab/merge_request_templates/Default.md` with the same content.

If no remote or unknown host, write `.github/pull_request_template.md` (GitHub is the most common).

## Step 6: Create Setup Script + .gitignore Additions

### `scripts/setup.sh`

```bash
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
```

Run: `bash scripts/setup.sh`

### `.gitshitrc` — Configuration

Create `.gitshitrc` at project root (if it doesn't already exist). Auto-detect the default branch:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
if [ -z "$DEFAULT_BRANCH" ]; then
  PROTECTED_BRANCHES="main|master"
else
  PROTECTED_BRANCHES="$DEFAULT_BRANCH"
fi
```

Then write:

```bash
# .gitshitrc — git-shit configuration
# Team defaults. Individual devs can override with env vars (GIT_SHIT_<KEY>).
# This file should be committed to your repo.

COMMIT_MSG_MODE=warn           # strict | warn | off
SECRET_SCAN=on                 # on | off
LARGE_COMMIT_THRESHOLD=200     # line count before warning
PROTECTED_BRANCHES=$PROTECTED_BRANCHES
```

Replace `$PROTECTED_BRANCHES` with the auto-detected value.

### `.gitmessage` — Commit Template

Create `.gitmessage` at project root:

```
<type>(<scope>): <description>

# Types: feat fix refactor docs test chore style perf ci build revert
# Example: feat(auth): add OAuth2 login flow
#
# Tip: use imperative mood ("add" not "added"), no period at end
# Keep first line under 72 characters
```

This pairs with the commit-msg hook: the template shows the format, the hook enforces it.

### .gitignore additions

Check if `.gitignore` exists. If not, create one. If it does, append missing entries. Use language-appropriate patterns:

**All languages:**
```
.env
.env.*
.DS_Store
*.log
```

**TypeScript/JavaScript:**
```
node_modules/
dist/
build/
coverage/
.next/
```

**Python:**
```
__pycache__/
*.pyc
.venv/
venv/
dist/
*.egg-info/
.pytest_cache/
```

**Go:**
```
/bin/
/vendor/
```

**Rust:**
```
/target/
```

Don't duplicate entries already in .gitignore.

## Step 7: Audit Mode

When `audit` argument is passed, don't write anything. Instead analyze and report:

```
Git Shit Audit
==============

Hooks:
  pre-push:            ✅ installed / ❌ missing
  pre-commit:          ✅ installed / ❌ missing
  commit-msg:          ✅ installed / ❌ missing
  prepare-commit-msg:  ✅ installed / ❌ missing
  pre-rebase:          ✅ installed / ❌ missing
  post-merge:          ✅ installed / ❌ missing

  Hook source: core.hooksPath → $PATH / .git/hooks/ (default)

Files:
  .gitattributes:  ✅ present / ❌ missing
  .gitignore:      ✅ present (N entries) / ❌ missing
  .gitmessage:     ✅ present / ❌ missing
  .gitshitrc:      ✅ present / ❌ missing
  PR template:     ✅ present / ❌ missing
  setup.sh:        ✅ present / ❌ missing

Config:
  merge.ours.driver:  ✅ configured / ❌ missing (lock file merges silently broken)
  commit.template:    ✅ set → $PATH / ❌ not set
  rerere.enabled:     ✅ true / ❌ not enabled
  core.hooksPath:     ✅ set → $PATH / ⚠️ not set (using .git/hooks/)

Recommended Config:
  merge.conflictstyle:    ✅ zdiff3 / ❌ not set
  push.autoSetupRemote:   ✅ true / ❌ not set
  diff.algorithm:         ✅ histogram / ❌ not set
  commit.verbose:         ✅ true / ❌ not set
  diff.colorMoved:        ✅ default / ❌ not set
  branch.sort:            ✅ -committerdate / ❌ not set
  fetch.prune:            ✅ true / ❌ not set
  rebase.autosquash:      ✅ true / ❌ not set
  rebase.autostash:       ✅ true / ❌ not set

Configuration:
  .gitshitrc:             ✅ present / ❌ missing
  COMMIT_MSG_MODE:        $VALUE (strict|warn|off)
  SECRET_SCAN:            $VALUE (on|off)
  PROTECTED_BRANCHES:     $VALUE

Branch Protection:
  Default branch: $BRANCH
  Remote: $REMOTE (or "none")

Issues Found:
  - [list anything missing or misconfigured]

Run `/git-shit` (without `audit`) to fix everything.
```

Check for config issues using:
```bash
git config --get merge.ours.driver    # should be "true"
git config --get commit.template      # should point to .gitmessage
git config --get rerere.enabled       # should be "true"
git config --get core.hooksPath       # should point to scripts/git-hooks
git config --get merge.conflictstyle   # should be "zdiff3"
git config --get push.autoSetupRemote  # should be "true"
git config --get diff.algorithm        # should be "histogram"
git config --get commit.verbose        # should be "true"
git config --get diff.colorMoved       # should be "default"
git config --get branch.sort           # should be "-committerdate"
git config --get fetch.prune           # should be "true"
git config --get rebase.autosquash     # should be "true"
git config --get rebase.autostash      # should be "true"
```

## Step 8: Summary

After installation, print:

```
✅ Git shit installed

  Hooks (scripts/git-hooks/ via core.hooksPath):
    pre-push              — Can't push to protected branches directly
    pre-commit            — Scans for secrets + warns on big commits
    commit-msg            — Conventional commits (configurable: strict/warn/off)
    prepare-commit-msg    — Auto-fills prefix from branch name
    pre-rebase            — Blocks rebasing pushed commits
    post-merge            — Reminds to install deps after pull

  Files:
    .gitattributes        — Binary handling + lock file merge
    .gitignore            — Updated with standard ignores
    .gitmessage           — Commit message template
    .gitshitrc            — Hook configuration (shared by team)
    .github/pull_request_template.md — PR template
    scripts/setup.sh      — One-command setup for teammates

  Config:
    core.hooksPath        → scripts/git-hooks
    merge.ours.driver     → true (lock files keep yours on conflict)
    commit.template       → .gitmessage
    rerere.enabled        → true (remembers conflict resolutions)
    merge.conflictstyle   → zdiff3 (better conflict display)
    push.autoSetupRemote  → true (no more set-upstream errors)
    diff.algorithm        → histogram (cleaner diffs)
    commit.verbose        → true (see diff in commit editor)
    diff.colorMoved       → default (moved lines highlighted)
    branch.sort           → -committerdate (recent branches first)
    fetch.prune           → true (stale remote branches auto-cleaned)
    rebase.autosquash     → true (fixup! commits auto-processed)
    rebase.autostash      → true (auto-stash during rebase)

  Tell your team:
    "Run 'bash scripts/setup.sh' after cloning"

  Test it:
    git checkout -b feat/test-hooks
    git commit -m "test" → should show conventional commit suggestion
    git commit            → editor opens with "feat: " pre-filled

  Level Up Further:
    lazygit     — terminal UI for git
    delta       — syntax-highlighted diffs
    difftastic  — structural diffs that understand your language
    git-absorb  — auto-amend fixups into the right commits
    Run 'bash scripts/git-shit-tools.sh' for install commands.
```
