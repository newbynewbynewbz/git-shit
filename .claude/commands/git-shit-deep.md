---
name: git-shit-deep
description: Deep reference for /git-shit — language-specific gitignore, per-ecosystem lockfile entries, full audit format, manual hook bodies when the installer cannot be used.
argument: ""
model-hint: sonnet
---

# /git-shit deep reference

Only load this when you cannot run `install.sh` and must hand-build pieces from scratch, or when you need exhaustive language/ecosystem detail.

## When the installer script IS reachable

Stop. Use it. This file is for cases where you're in a sandboxed environment or a stripped-down repo without the git-shit template nearby.

## Manual hook bodies

The canonical sources live in `repo/template/git-hooks/` of the git-shit repo. Read those with the Read tool rather than reproducing them from memory — the regex lists (especially secret patterns) are updated and this file WILL drift. If the template is absolutely unreachable, see the git history of the git-shit repo for the last known-good bodies.

## `.gitattributes` — per-language content

Build up from a common base + language-specific + package-manager-specific lines.

### Common base

```
# Auto-normalize line endings
* text=auto

# Images
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

# Dev-only files excluded from git archive / release tarballs
.github/ export-ignore
scripts/ export-ignore
.claude/ export-ignore
```

### Lock files by package manager

| Package manager | Line |
|---|---|
| npm | `package-lock.json -diff merge=ours` |
| bun | `bun.lockb binary` |
| yarn | `yarn.lock -diff merge=ours` |
| pnpm | `pnpm-lock.yaml -diff merge=ours` |
| pip/uv | `requirements.txt -diff merge=ours` |
| cargo | `Cargo.lock -diff merge=ours` |
| go | `go.sum -diff merge=ours` |
| ruby | `Gemfile.lock -diff merge=ours` |

The `merge=ours` strategy requires `git config merge.ours.driver true` (setup.sh handles this).

### Language-specific additions

- **Go:** `*.pb.go linguist-generated=true`
- **Rust:** `*.rlib binary`
- **Python:** `*.pyc binary`, `*.pyo binary`
- **C/C++:** `*.o binary`, `*.a binary`, `*.so binary`

## `.gitignore` seed content

### All languages
```
.env
.env.*
.DS_Store
*.log
```

### TypeScript/JavaScript
```
node_modules/
dist/
build/
coverage/
.next/
.turbo/
.vercel/
```

### Python
```
__pycache__/
*.pyc
*.pyo
.venv/
venv/
dist/
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/
```

### Go
```
/bin/
/vendor/
*.test
*.out
```

### Rust
```
/target/
**/*.rs.bk
Cargo.lock  # only for libraries, keep it for binaries
```

Append missing lines; don't duplicate entries already present.

## PR template

### GitHub (`.github/pull_request_template.md`)
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
<!-- If UI change, add before/after screenshots. Delete if N/A. -->
```

### GitLab
Same content at `.gitlab/merge_request_templates/Default.md`.

## `.gitmessage` commit template
```
<type>(<scope>): <description>

# Types: feat fix refactor docs test chore style perf ci build revert research
# Example: feat(auth): add OAuth2 login flow
#
# Tip: imperative mood ("add" not "added"), no period at end
# Keep first line under 72 characters
```

## Full audit output format

```
Git Shit Audit
==============

Profile:
  GIT_SHIT_PROFILE:    solo | team | strict (or "unset — defaults to solo")

Hooks:
  pre-commit, commit-msg, prepare-commit-msg, pre-rebase, pre-push, post-merge
  Hook source:         core.hooksPath → <path> / .git/hooks/ (default)

Files:
  .gitattributes, .gitignore, .gitmessage, .gitshitrc, PR template, setup.sh

Config (must-have):
  merge.ours.driver, commit.template, rerere.enabled, core.hooksPath

Config (recommended):
  merge.conflictstyle=zdiff3, push.autoSetupRemote=true, diff.algorithm=histogram,
  commit.verbose=true, diff.colorMoved=default, branch.sort=-committerdate,
  fetch.prune=true, rebase.autosquash=true, rebase.autostash=true

Active resolved knobs (from .gitshitrc + profile):
  TEACH_MODE, COMMIT_MSG_MODE, BRANCH_NAMING_MODE, SECRET_SCAN,
  PROTECTED_BRANCHES, LARGE_COMMIT_THRESHOLD

Branch Protection:
  Default branch:  <branch>
  Remote:          <github|gitlab|none>

Issues Found:
  - <enumerate missing/misconfigured items>

Run /git-shit to apply fixes.
```

## Detection heuristics for `new <name>` setup

When asking questions, pre-fill sensible defaults from the user's environment:
- If `package.json` exists anywhere nearby → TypeScript/JavaScript
- If `pyproject.toml` / `setup.py` → Python
- If `go.mod` → Go
- If `Cargo.toml` → Rust

Don't ask if you can infer with high confidence.
