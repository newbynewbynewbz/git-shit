# git-shit

Level up any repo's git setup in 60 seconds. Hooks, config, secret scanning, conventional commits, the works.

Drop into any repo. No Claude Code knowledge needed. Zero dependencies.

## What You Get

### Hooks (6 total, via `core.hooksPath`)

- **pre-commit** — scans for secrets (hard block) + warns on big commits (200+ lines) + whitespace issues.
- **commit-msg** — conventional commit format (configurable: strict, warn, or off). Default: warn.
- **pre-push** — blocks direct pushes to protected branches. PR-only workflow.
- **prepare-commit-msg** — auto-fills commit prefix from branch name (`feat/login` → `feat: `).
- **pre-rebase** — blocks rebasing commits already pushed to remote. Protects shared history.
- **post-merge** — reminds you to reinstall dependencies when lock files change after pull.

### Configuration (`.gitshitrc`)

All hooks read from `.gitshitrc` in your repo root. Team defaults, personal overrides via env vars.

```bash
# .gitshitrc
COMMIT_MSG_MODE=warn           # strict | warn | off
SECRET_SCAN=on                 # on | off
LARGE_COMMIT_THRESHOLD=200     # line count before warning
PROTECTED_BRANCHES=main        # pipe-separated: main|develop|staging
```

Override per-command with env vars:
```bash
GIT_SHIT_COMMIT_MSG=off git commit -m "yolo"
GIT_SHIT_SECRET_SCAN=off git commit -m "test: add fixture with fake key"
```

### Git Config (set by setup script)

Opinionated defaults applied repo-local:

- `core.hooksPath` → hooks live in repo, auto-update on `git pull`
- `merge.conflictstyle zdiff3` → shows original code in conflicts
- `push.autoSetupRemote true` → no more "set-upstream" errors
- `diff.algorithm histogram` → cleaner diffs
- `commit.verbose true` → see diff in commit editor
- `diff.colorMoved default` → highlights moved lines
- `branch.sort -committerdate` → recent branches first
- `fetch.prune true` → auto-cleans stale remote branches
- `rebase.autosquash true` → auto-processes fixup! commits
- `rebase.autostash true` → auto-stash during rebase
- `merge.ours.driver true` → lock files keep yours on conflict
- `commit.template .gitmessage` → format shown in editor
- `rerere.enabled true` → remembers conflict resolutions

### Files

- **.gitattributes** — binary handling, lock file merge strategy, diff driver hints.
- **.gitmessage** — commit message template showing correct format.
- **.gitshitrc** — hook configuration (committed, shared by team).
- **PR template** — consistent pull request format.
- **setup.sh** — one command to set up everything after cloning.
- **git-shit-tools.sh** — recommended tool discovery (lazygit, delta, etc.).

## Quick Start (Claude Code)

```bash
# Copy the skill file
mkdir -p YOUR_PROJECT/.claude/commands
cp .claude/commands/git-shit.md YOUR_PROJECT/.claude/commands/

# Run it
claude /git-shit

# Or just audit what's missing
claude /git-shit audit
```

## Quick Start (No Claude Code)

```bash
# Clone git-shit
git clone https://github.com/newbynewbynewbz/git-shit.git

# Install into your project
cd YOUR_PROJECT
bash /path/to/git-shit/install.sh
```

That copies hooks, config files, and runs setup. Test it:

```bash
git commit -m "test"          # Suggestion to add prefix (warn mode)
git commit -m "feat: hello"   # Passes
```

### For Your Teammates

After cloning your repo, teammates just run:

```bash
bash scripts/setup.sh
```

All hooks and config files are already in the repo — the setup script configures git to use them.

### Recommended Tools

After setup, discover tools that make git even better:

```bash
bash scripts/git-shit-tools.sh
```

## What's in the Box

```
git-shit/
  install.sh                      <- One-command installer
  .claude/commands/
    git-shit.md                   <- Claude Code skill
  template/
    git-hooks/
      pre-commit                  <- Secret scanning + big commit warning
      commit-msg                  <- Conventional commits (configurable)
      pre-push                    <- Blocks pushes to protected branches
      prepare-commit-msg          <- Auto-fills prefix from branch
      pre-rebase                  <- Blocks rebasing pushed commits
      post-merge                  <- Reminds to reinstall deps
    scripts/
      setup.sh                    <- One-command setup for teammates
      setup-hooks.sh              <- Backward compat wrapper
      git-shit-tools.sh           <- Recommended tool discovery
    .gitshitrc                    <- Default configuration
    .gitattributes                <- Binary, lock files, diff drivers
    .gitmessage                   <- Commit message template
    .github/
      pull_request_template.md    <- PR template
  README.md
  LICENSE
```

## Want More?

If you want the full Claude Code collaboration setup — AI hooks, portable skills, built-in courses, onboarding guide — check out [big-gulps-huh](https://github.com/newbynewbynewbz/big-gulps-huh).

## License

MIT — take it, use it, share it.
