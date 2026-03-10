# git-shit

Level up any repo's git setup in 60 seconds. Hooks, conventional commits, PR workflow, the works.

Drop into any repo. No Claude Code knowledge needed.

## What You Get

### Hooks (6 total, via `core.hooksPath`)

- **pre-push** — blocks direct pushes to main. PR-only workflow.
- **pre-commit** — warns on big commits (200+ lines) + whitespace issues. Suggests `git add -p`.
- **commit-msg** — enforces `feat:` / `fix:` / `docs:` prefixes. Searchable history.
- **prepare-commit-msg** — auto-fills commit prefix from branch name (`feat/login` → `feat: `).
- **pre-rebase** — blocks rebasing commits already pushed to remote. Protects shared history.
- **post-merge** — reminds you to reinstall dependencies when lock files change after pull.

### Files

- **.gitattributes** — binary handling, lock file merge strategy, diff driver hints, export-ignore.
- **.gitmessage** — commit message template showing correct format before you type.
- **.gitignore** — language-aware standard ignores.
- **PR template** — consistent pull request format for the team.
- **setup-hooks.sh** — one command to set up hooks + config after cloning.
- **audit mode** — check what's missing without changing anything.

### Config (set by setup script)

- `core.hooksPath` → hooks live in repo, auto-update on `git pull`
- `merge.ours.driver` → lock files keep your version on merge conflicts
- `commit.template` → conventional commit format shown in editor
- `rerere.enabled` → Git remembers how you resolved conflicts

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

Don't use Claude Code? One command:

```bash
# Clone git-shit
git clone https://github.com/newbynewbynewbz/git-shit.git

# Install into your project
cd YOUR_PROJECT
bash /path/to/git-shit/install.sh
```

That copies hooks, config files, and runs setup. Test it:

```bash
git commit -m "test"          # Rejected — no prefix
git commit -m "feat: hello"   # Passes
```

### For Your Teammates

After cloning your repo, teammates just run:

```bash
bash scripts/setup-hooks.sh
```

All hooks and config files are already in the repo — the setup script configures git to use them.

## What's in the Box

```
git-shit/
  install.sh                      <- One-command installer
  .claude/commands/
    git-shit.md                   <- The skill file
  template/
    git-hooks/
      pre-push                    <- Blocks pushes to main
      pre-commit                  <- Warns on big commits + whitespace
      commit-msg                  <- Enforces conventional commits
      prepare-commit-msg          <- Auto-fills prefix from branch
      pre-rebase                  <- Blocks rebasing pushed commits
      post-merge                  <- Reminds to reinstall deps
    scripts/
      setup-hooks.sh              <- One-command setup for teammates
    .gitattributes                <- Binary, lock files, diff drivers
    .gitmessage                   <- Commit message template
    .github/
      pull_request_template.md    <- PR template
  README.md
  LICENSE
```

## Want More?

If you want the full Claude Code collaboration setup — AI hooks, 9 portable skills, built-in courses, onboarding guide — check out [big-gulps-huh](https://github.com/newbynewbynewbz/big-gulps-huh).

## License

MIT — take it, use it, share it.
