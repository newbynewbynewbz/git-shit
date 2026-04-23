# git-shit

Level up any repo's git setup in 60 seconds. Hooks, config, secret scanning, conventional commits — zero dependencies, silent by default.

## Philosophy

**Quiet on success, loud on failure.** Hooks stay out of the way when everything's fine and only speak up when there's something actionable. The default profile ships with teach-mode off and conventional-commit enforcement off — because that's what solo devs actually want. Opt up to `team` or `strict` when the ceremony earns its keep.

## Profiles (v0.2+)

| Profile | When | What changes |
|---|---|---|
| **solo** (default) | One committer, velocity matters | Teach off · CC off · Branch naming off · Threshold 500 |
| **team** | Multiple committers, CC matters | Teach on · CC warn · Branch naming warn · Threshold 200 |
| **strict** | Regulated / audited work | Teach on · CC strict · Branch naming strict · Threshold 100 · Protects main\|develop |

All profiles keep `SECRET_SCAN=on` and `PROTECTED_BRANCHES=main`. Safety is non-negotiable.

Set a profile with `--profile` at install time, or edit `GIT_SHIT_PROFILE` in `.gitshitrc` after. Any individual knob you set explicitly overrides the profile default.

## What You Get

### Hooks (6 total, via `core.hooksPath`)

- **pre-commit** — secret scanning (hard block). Patterns: AWS, GitHub PAT, GitHub fine-grained, Anthropic, OpenAI project, Supabase, Vercel, Databricks, DigitalOcean, Fly.io, generic `sk-...`, PEM private keys.
- **commit-msg** — conventional commit format (off/warn/strict by profile).
- **pre-push** — blocks direct pushes to protected branches. PR-only workflow.
- **prepare-commit-msg** — auto-fills commit prefix from branch name (`feat/login` → `feat: `) when CC is on.
- **pre-rebase** — blocks rebasing commits already pushed to remote.
- **post-merge** — reminds you to reinstall deps when lock files change.

### Configuration (`.gitshitrc`)

```bash
# Profile sets defaults for everything below.
GIT_SHIT_PROFILE=solo

# Uncomment to override any profile default:
# TEACH_MODE=off
# COMMIT_MSG_MODE=off
# BRANCH_NAMING_MODE=off
# LARGE_COMMIT_THRESHOLD=500
# SECRET_SCAN=on
# PROTECTED_BRANCHES=main
```

Override per-command with env vars — useful for test fixtures:
```bash
GIT_SHIT_SECRET_SCAN=off git commit -m "test: add fixture with fake key"
GIT_SHIT_COMMIT_MSG=off git commit -m "wip"
```

### Git Config (applied by setup.sh)

Opinionated defaults, repo-local:

- `core.hooksPath` → hooks live in repo, auto-update on `git pull`
- `merge.conflictstyle zdiff3`, `diff.algorithm histogram`, `diff.colorMoved default`
- `push.autoSetupRemote true` — no more "set-upstream" errors
- `commit.verbose true` — see diff in the commit editor
- `branch.sort -committerdate`, `fetch.prune true`
- `rebase.autosquash true`, `rebase.autostash true`
- `merge.ours.driver true` + `rerere.enabled true`

Optional (`--fsmonitor` flag): `core.fsmonitor=true` + `core.untrackedCache=true` — 4× faster `git status` on anything with >5k files.

### Files

- **`.gitshitrc`** — profile + knobs, committed to the repo
- **`.gitattributes`** — binary handling, lock file merge strategy
- **`.gitmessage`** — commit message template
- **`.github/pull_request_template.md`** — PR template
- **`scripts/git-hooks/`** — the 6 hooks
- **`scripts/lib/`** — profile resolver + output helpers (new in v0.2)
- **`scripts/setup.sh`** — one-command setup for teammates

## Quick Start

```bash
# Clone git-shit
git clone https://github.com/newbynewbynewbz/git-shit.git

# Install into your project (solo profile, the default)
cd YOUR_PROJECT
bash /path/to/git-shit/install.sh

# Or opt up to team/strict
bash /path/to/git-shit/install.sh --profile team
```

### Claude Code users

```bash
# Copy the skill into your project
mkdir -p YOUR_PROJECT/.claude/commands
cp .claude/commands/git-shit*.md YOUR_PROJECT/.claude/commands/

# Then from inside your project:
claude /git-shit                    # install with solo profile
claude /git-shit --profile team     # install with team profile
claude /git-shit audit              # report setup health
```

### Teammates (after you commit git-shit into the repo)

```bash
bash scripts/setup.sh
```

### Upgrading an existing install

```bash
bash /path/to/git-shit/install.sh update
bash /path/to/git-shit/install.sh update --profile team   # also flip profile
```

Update mode preserves `.gitshitrc` customizations, refreshes hooks/libs/scripts.

## Health check

```bash
bash scripts/git-shit-status.sh
```

Reports: active profile, resolved knob values, hook install state, recommended git config drift, missing template files.

## What's in the Box

```
git-shit/
  install.sh                      <- One-command installer
  .claude/commands/
    git-shit.md                   <- Lean Claude Code skill (~6KB)
    git-shit-deep.md              <- Reference for edge cases (~5KB, lazy-loaded)
  template/
    git-hooks/                    <- 6 hooks, quiet-on-success
    scripts/
      lib/profile.sh              <- Profile → defaults resolver
      lib/output.sh               <- gs_teach / gs_err / gs_fail
      setup.sh                    <- Idempotent, silent when unchanged
      git-shit-status.sh          <- Audit
      git-shit-oops.sh            <- Quick fixes for common mistakes
      git-shit-workflow.sh        <- Branching strategy advisor
      git-shit-tools.sh           <- lazygit / delta / difftastic finder
    .gitshitrc, .gitattributes, .gitmessage, .github/pull_request_template.md
  README.md, LICENSE
```

## Want More?

For the full Claude Code collaboration setup — AI hooks, portable skills, built-in courses, onboarding — check out [big-gulps-huh](https://github.com/newbynewbynewbz/big-gulps-huh).

## License

MIT.
