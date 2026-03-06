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
- Existing hooks in .git/hooks/?
- Existing .gitattributes?
- Existing .gitignore?
- Existing PR template?
- Remote origin? (GitHub, GitLab, Bitbucket?)
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

Write all 3 hooks to `.git/hooks/` and `chmod +x` each one.

### `.git/hooks/pre-push`

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

### `.git/hooks/pre-commit`

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
fi

exit 0
```

### `.git/hooks/commit-msg`

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

# Lock files — don't try to manually merge, just take one version
$LOCKFILE_ENTRY

# Auto-normalize line endings
* text=auto
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
# Git Shit: One-command hook installer
# Run: bash scripts/setup-hooks.sh

HOOK_DIR=".git/hooks"

if [ ! -d ".git" ]; then
  echo "❌ Not a git repo. Run from project root."
  exit 1
fi

echo "Installing git hooks..."
echo ""

for hook in pre-push pre-commit commit-msg; do
  if [ -f "$HOOK_DIR/$hook" ]; then
    chmod +x "$HOOK_DIR/$hook"
    echo "  ✅ $hook"
  else
    echo "  ❌ $hook missing"
  fi
done

echo ""
echo "Done. Run 'git commit -m \"test\"' to verify commit-msg hook works."
echo "(It should reject that message — no conventional prefix.)"
```

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
  pre-push:    ✅ installed / ❌ missing
  pre-commit:  ✅ installed / ❌ missing
  commit-msg:  ✅ installed / ❌ missing

Files:
  .gitattributes:  ✅ present / ❌ missing
  .gitignore:      ✅ present (N entries) / ❌ missing
  PR template:     ✅ present / ❌ missing
  setup-hooks.sh:  ✅ present / ❌ missing

Branch Protection:
  Default branch: $BRANCH
  Remote: $REMOTE (or "none")

Issues Found:
  - [list anything missing or misconfigured]

Run `/git-shit` (without `audit`) to fix everything.
```

## Step 8: Summary

After installation, print:

```
✅ Git shit installed

  Hooks:
    .git/hooks/pre-push       — Can't push to $DEFAULT_BRANCH directly
    .git/hooks/pre-commit     — Warns on big commits (200+ lines)
    .git/hooks/commit-msg     — Requires feat:/fix:/docs:/etc.

  Files:
    .gitattributes            — Binary handling + lock file merge
    .gitignore                — Updated with standard ignores
    .github/pull_request_template.md — PR template
    scripts/setup-hooks.sh    — Hook installer for teammates

  Tell your team:
    "Run 'bash scripts/setup-hooks.sh' after cloning"

  Test it:
    git commit -m "test" → should be rejected (no prefix)
    git commit -m "test: verify hooks" → should pass
```
