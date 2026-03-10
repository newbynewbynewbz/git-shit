---
name: git-shit
description: Pimp out any repo's git setup — hooks, conventional commits, PR workflow, branch protection, templates. Drop in and go.
argument: "[path|new <name>|audit]"
model-hint: sonnet
---

# Git Shit — Level Up Your Git Game

Drop this into any repo and instantly get: commit message enforcement, push protection, PR templates, gitattributes, branch naming, and a setup script for the whole team.

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
```

If `new <name>`: create directory, `cd`, `git init`.
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
- main (Recommended)
- master
- Other

Store as `$LANG`, `$PKG_MGR`, `$DEFAULT_BRANCH`.

## Step 3: Install Git Hooks

Write all 6 hooks to `scripts/git-hooks/` and `chmod +x` each one. Then set `core.hooksPath`:

```bash
git config core.hooksPath scripts/git-hooks
```

This keeps hooks version-controlled and auto-updates them on `git pull`. No copy step needed for teammates — just `bash scripts/setup-hooks.sh`.

### `scripts/git-hooks/pre-push`

Blocks direct pushes to the default branch. Forces PR workflow.

```bash
#!/bin/bash
# Git Shit: Pre-push hook
# Blocks direct pushes to $DEFAULT_BRANCH — forces PR workflow
# Bypass: git push --no-verify (emergencies only)

BRANCH=$(git branch --show-current)
REMOTE="$1"
PROTECTED="$DEFAULT_BRANCH"

while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_ref" = "refs/heads/$PROTECTED" ] && [ "$BRANCH" = "$PROTECTED" ]; then
    if echo "$local_ref" | grep -q "refs/tags/"; then
      continue
    fi

    echo ""
    echo "🛑 Direct push to $PROTECTED blocked"
    echo ""
    echo "  Use the PR workflow:"
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

exit 0
```

Replace `$DEFAULT_BRANCH` and `$PROTECTED` with the actual branch name from Step 2.

### `scripts/git-hooks/pre-commit`

Non-blocking warning when staged changes are large.

```bash
#!/bin/bash
# Git Shit: Pre-commit hook
# Warns (non-blocking) when staged changes exceed threshold

WARN_THRESHOLD=200

INSERTIONS=$(git diff --cached --numstat | awk '{sum+=$1} END{print sum+0}')

if [ "$INSERTIONS" -gt "$WARN_THRESHOLD" ]; then
  echo ""
  echo "⚠️  Heads up: $INSERTIONS lines staged (threshold: $WARN_THRESHOLD)"
  echo ""
  echo "  Staged files:"
  git diff --cached --stat | tail -1
  echo ""
  echo "  Big commits are hard to review and hard to revert."
  echo "  Ask yourself: is this really ONE change?"
  echo ""
  echo "  Tip: use 'git add -p' to stage changes hunk-by-hunk"
  echo "       and split this into multiple focused commits."
  echo ""
fi

# Non-blocking whitespace check
if ! git diff --cached --check > /dev/null 2>&1; then
  echo "⚠️  Whitespace issues detected (trailing spaces, mixed tabs)"
  echo "  Run: git diff --cached --check    to see details"
  echo ""
fi

exit 0
```

### `scripts/git-hooks/commit-msg`

Enforces conventional commit prefixes. Blocking.

```bash
#!/bin/bash
# Git Shit: Commit-msg hook
# Requires conventional commit prefixes
# Valid: feat: fix: refactor: docs: test: chore: style: perf: ci: build: revert:

MSG_FILE="$1"
MSG=$(head -1 "$MSG_FILE")

# Allow merge commits
if echo "$MSG" | grep -qE '^Merge '; then
  exit 0
fi

# Allow squash merge commits from GitHub/GitLab
if echo "$MSG" | grep -qE '^\S+.*\(#[0-9]+\)$'; then
  exit 0
fi

# Allow fixup/squash commits (interactive rebase)
if echo "$MSG" | grep -qE '^(fixup|squash)! '; then
  exit 0
fi

# Check for conventional commit prefix
if echo "$MSG" | grep -qE '^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\([a-zA-Z0-9_-]+\))?!?: .+'; then
  exit 0
fi

echo ""
echo "🛑 Bad commit message"
echo ""
echo "  Got:      $MSG"
echo "  Expected: type(scope): description"
echo ""
echo "  Types: feat fix refactor docs test chore style perf ci build revert"
echo "  Scope is optional: feat(auth): fix(api):"
echo ""
echo "  Examples:"
echo "    feat: add user login"
echo "    fix(api): handle empty response"
echo "    docs: update README"
echo ""
exit 1
```

### `scripts/git-hooks/prepare-commit-msg`

Pre-fills conventional commit prefix from branch name. Fires before the editor opens.

```bash
#!/bin/bash
# Git Shit: prepare-commit-msg hook
# Pre-fills conventional commit prefix from branch name

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"

# Only auto-fill for new commits (not merges, amends, squashes)
if [ -n "$COMMIT_SOURCE" ]; then
  exit 0
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

# Extract type from branch: feat/add-login -> feat
TYPE=$(echo "$BRANCH" | sed -n 's|^\(feat\|fix\|refactor\|docs\|test\|chore\|style\|perf\|ci\|build\|revert\)/.*|\1|p')

# Extract scope: feat/auth/add-login -> auth
SCOPE=$(echo "$BRANCH" | sed -n 's|^\(feat\|fix\|refactor\|docs\|test\|chore\|style\|perf\|ci\|build\|revert\)/\([a-zA-Z0-9_-]*\)/.*|\2|p')

FIRST_LINE=$(head -1 "$COMMIT_MSG_FILE")
if [ -n "$TYPE" ] && [ -z "$FIRST_LINE" ]; then
  if [ -n "$SCOPE" ]; then
    PREFIX="$TYPE($SCOPE): "
  else
    PREFIX="$TYPE: "
  fi
  TEMP=$(mktemp)
  echo "$PREFIX" > "$TEMP"
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
# Prevents rebasing commits already pushed to remote

UPSTREAM="$1"
BRANCH="$2"

if [ -z "$BRANCH" ]; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
fi

if [ -z "$BRANCH" ]; then
  exit 0
fi

# Check if branch has a remote tracking ref
REMOTE_REF=$(git rev-parse --verify "origin/$BRANCH" 2>/dev/null)
if [ -z "$REMOTE_REF" ]; then
  exit 0  # Local only — safe to rebase
fi

# Check for pushed commits that would be rewritten
WOULD_REWRITE=$(git log --oneline "$UPSTREAM..$BRANCH" 2>/dev/null)
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
  echo "  Instead: git merge $UPSTREAM"
  echo ""
  echo "  Solo branch? git rebase $UPSTREAM --no-verify"
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
# Detects dependency changes and reminds you to reinstall

CHANGED=$(git diff-tree -r --name-only ORIG_HEAD HEAD 2>/dev/null)
if [ -z "$CHANGED" ]; then
  exit 0
fi

NEEDS_INSTALL=""
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
elif echo "$CHANGED" | grep -q "requirements.txt\|Pipfile.lock\|poetry.lock"; then
  NEEDS_INSTALL="pip install -r requirements.txt"
elif echo "$CHANGED" | grep -q "go.sum"; then
  NEEDS_INSTALL="go mod download"
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
# Requires: git config merge.ours.driver true (setup-hooks.sh handles this)
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

### `scripts/setup-hooks.sh`

```bash
#!/bin/bash
# Git Shit: One-command setup for new cloners
# Run: bash scripts/setup-hooks.sh

set -e
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "❌ Not a git repo. Run from inside a project."
  exit 1
fi
cd "$REPO_ROOT"

echo ""
echo "⚙️  Git Shit — Setting up your repo"
echo ""

# 1. Hook installation via core.hooksPath (hooks live in repo, auto-update on pull)
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
else
  echo "  ⚠️  No hooks directory found"
fi

# 2. Configure merge.ours driver (required for lock file merge strategy)
git config merge.ours.driver true
echo "  ✅ merge.ours driver configured"

# 3. Commit template
if [ -f ".gitmessage" ]; then
  git config commit.template .gitmessage
  echo "  ✅ Commit template → .gitmessage"
fi

# 4. Enable rerere (remembers conflict resolutions)
git config rerere.enabled true
echo "  ✅ rerere enabled"

echo ""
echo "Done. Test: git commit -m \"test\" (should be rejected)"
```

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
  PR template:     ✅ present / ❌ missing
  setup-hooks.sh:  ✅ present / ❌ missing

Config:
  merge.ours.driver:  ✅ configured / ❌ missing (lock file merges silently broken)
  commit.template:    ✅ set → $PATH / ❌ not set
  rerere.enabled:     ✅ true / ❌ not enabled
  core.hooksPath:     ✅ set → $PATH / ⚠️ not set (using .git/hooks/)

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
```

## Step 8: Summary

After installation, print:

```
✅ Git shit installed

  Hooks (scripts/git-hooks/ via core.hooksPath):
    pre-push              — Can't push to $DEFAULT_BRANCH directly
    pre-commit            — Warns on big commits + whitespace issues
    commit-msg            — Requires feat:/fix:/docs:/etc.
    prepare-commit-msg    — Auto-fills prefix from branch name
    pre-rebase            — Blocks rebasing pushed commits
    post-merge            — Reminds to install deps after pull

  Files:
    .gitattributes        — Binary handling + lock file merge
    .gitignore            — Updated with standard ignores
    .gitmessage           — Commit message template
    .github/pull_request_template.md — PR template
    scripts/setup-hooks.sh — One-command setup for teammates

  Config:
    core.hooksPath        → scripts/git-hooks
    merge.ours.driver     → true (lock files keep yours on conflict)
    commit.template       → .gitmessage
    rerere.enabled        → true (remembers conflict resolutions)

  Tell your team:
    "Run 'bash scripts/setup-hooks.sh' after cloning"

  Test it:
    git checkout -b feat/test-hooks
    git commit -m "test" → should be rejected (no prefix)
    git commit            → editor opens with "feat: " pre-filled
```
