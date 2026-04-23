---
name: git-shit
description: Install or audit git-shit (hooks, conventional commits, PR template, secret scanning, recommended config) in a target repo.
argument: "[path|new <name>|audit] [--profile solo|team|strict]"
model-hint: sonnet
---

# /git-shit

Prefer invoking the installer script — it's authoritative and handles every case. Only hand-roll individual pieces when the script can't be used.

## Arguments

| Input | Action |
|-------|--------|
| *(empty)* | Install into the current repo with default profile (solo) |
| `<path>` | `cd <path>` first, then install |
| `new <name>` | Create `<name>/`, `git init`, then install |
| `audit` | Report setup health. No writes. |
| `--profile solo\|team\|strict` | Pick a profile. See Profiles below. |

## Profiles

| Profile | When | Knobs |
|---|---|---|
| **solo** (default) | One committer, velocity matters | TEACH_MODE=off, COMMIT_MSG=off, BRANCH_NAMING=off, LARGE_THRESHOLD=500, SECRET_SCAN=on, PROTECTED=main |
| **team** | Multiple committers, CC matters | TEACH_MODE=on, COMMIT_MSG=warn, BRANCH_NAMING=warn, LARGE_THRESHOLD=200, SECRET_SCAN=on, PROTECTED=main |
| **strict** | Regulated / audited work | TEACH_MODE=on, COMMIT_MSG=strict, BRANCH_NAMING=strict, LARGE_THRESHOLD=100, SECRET_SCAN=on, PROTECTED=main\|develop |

Profiles set defaults. Explicit values in `.gitshitrc` always win.

## Happy path — install

```bash
# From the git-shit repo directory:
bash install.sh --profile solo              # into current repo
bash install.sh /path/to/repo --profile team
bash install.sh new my-project
```

The installer:
1. Copies hooks to `scripts/git-hooks/`
2. Copies libs to `scripts/lib/` (profile resolver + output helpers)
3. Copies setup scripts to `scripts/`
4. Creates `.gitattributes`, `.gitmessage`, `.gitshitrc`, `.github/pull_request_template.md`
5. Runs `bash scripts/setup.sh` to apply recommended git config

Then tell the user:
```
git add -A && git commit -m 'chore: add git-shit hooks and config'
```

## When to NOT just run install.sh

- **Existing install detected** (`.gitshitrc` or `scripts/git-hooks/` present) → use `bash install.sh update` instead
- **User asked for `audit`** → see Audit below; do not write
- **User wants a non-default profile** → pass `--profile <name>`

## Context detection

Before touching anything, check:

```bash
git rev-parse --git-dir          # is this a git repo?
git config --get core.hooksPath  # existing hooks redirect?
ls -la .git/hooks/ 2>/dev/null   # existing custom hooks?
test -f .gitshitrc               # prior install?
test -f scripts/git-hooks/pre-commit  # prior install (alt)
git remote get-url origin        # GitHub / GitLab / none?
```

If existing hooks are present and differ from template, ask the user (AskUserQuestion) whether to overwrite.

## Setup questions (only when `new <name>`)

Use AskUserQuestion:
1. **Primary language:** TypeScript/JavaScript (default) · Python · Go · Rust · Other
2. **Package manager:** npm · bun · yarn · pnpm · pip/uv · cargo · go modules · Other
3. **Profile:** solo (default) · team · strict

For existing repos, skip these — read the tree and infer.

## Audit mode

When argument is `audit`, do not write. Prefer running the bundled script:

```bash
bash scripts/git-shit-status.sh
```

If the repo has no git-shit install yet, the script won't exist — fall back to manual checks:

```bash
# Hooks
for h in pre-commit commit-msg pre-push prepare-commit-msg pre-rebase post-merge; do
  [ -x ".git/hooks/$h" ] || [ -x "scripts/git-hooks/$h" ] && echo "✓ $h" || echo "✗ $h"
done

# Files
for f in .gitattributes .gitmessage .gitshitrc .github/pull_request_template.md; do
  [ -f "$f" ] && echo "✓ $f" || echo "✗ $f"
done

# Config
for k in merge.ours.driver commit.template rerere.enabled core.hooksPath \
         merge.conflictstyle push.autoSetupRemote diff.algorithm commit.verbose \
         diff.colorMoved branch.sort fetch.prune rebase.autosquash rebase.autostash; do
  v=$(git config --get "$k" 2>/dev/null)
  [ -n "$v" ] && echo "✓ $k = $v" || echo "✗ $k"
done
```

Report: what's installed, what's missing, what differs from recommended. End with: `Run '/git-shit' to apply fixes`.

## Source of truth

If you need to read or hand-write a specific hook, setup step, or template file — read it from the git-shit repo rather than recreating from memory:

| File | Path in git-shit repo |
|------|----------------------|
| All 6 hooks | `template/git-hooks/` |
| Profile resolver | `template/scripts/lib/profile.sh` |
| Output helpers | `template/scripts/lib/output.sh` |
| Setup script | `template/scripts/setup.sh` |
| Status script | `template/scripts/git-shit-status.sh` |
| Oops cheatsheet | `template/scripts/git-shit-oops.sh` |
| Default .gitshitrc | `template/.gitshitrc` |
| .gitattributes | `template/.gitattributes` |
| .gitmessage | `template/.gitmessage` |
| PR template | `template/.github/pull_request_template.md` |

## After install — summary to user

```
✅ git-shit installed (profile: <PROFILE>)

Hooks (via core.hooksPath → scripts/git-hooks/):
  pre-commit, commit-msg, prepare-commit-msg, pre-rebase, pre-push, post-merge

Files:
  .gitshitrc, .gitattributes, .gitmessage, .github/pull_request_template.md

Next:
  git add -A && git commit -m 'chore: add git-shit hooks and config'

Teammates just run:
  bash scripts/setup.sh
```

## Deep reference

For full edge cases (language-specific .gitignore, per-ecosystem lockfile entries, audit output format), read `.claude/commands/git-shit-deep.md` in this repo.
