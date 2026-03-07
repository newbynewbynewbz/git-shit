# git-shit

Level up any repo's git setup in 60 seconds. Hooks, conventional commits, PR workflow, the works.

Drop into any repo. No Claude Code knowledge needed.

## What You Get

- **pre-push hook** — blocks direct pushes to main. PR-only workflow.
- **pre-commit hook** — warns when commits are over 200 lines. Keeps things atomic.
- **commit-msg hook** — enforces `feat:` / `fix:` / `docs:` prefixes. Searchable history.
- **.gitattributes** — binary handling, lock file merge strategy.
- **.gitignore** — language-aware standard ignores.
- **PR template** — consistent pull request format for the team.
- **setup-hooks.sh** — one command to install hooks after cloning.
- **audit mode** — check what's missing without changing anything.

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

Don't use Claude Code? Just copy the files directly:

```bash
# Clone this repo
git clone https://github.com/newbynewbynewbz/git-shit.git

# Copy git hooks to your project
cp git-shit/template/git-hooks/* YOUR_PROJECT/.git/hooks/
chmod +x YOUR_PROJECT/.git/hooks/*

# Copy the setup script
mkdir -p YOUR_PROJECT/scripts
cp git-shit/template/scripts/setup-hooks.sh YOUR_PROJECT/scripts/

# Copy .gitattributes
cp git-shit/template/.gitattributes YOUR_PROJECT/

# Copy PR template
cp -r git-shit/template/.github YOUR_PROJECT/

# Done. Test it:
cd YOUR_PROJECT
git commit -m "test"  # Should be rejected — no prefix
git commit -m "test: verify hooks"  # Should pass
```

## What's in the Box

```
git-shit/
  .claude/commands/
    git-shit.md                <- The skill file
  template/
    git-hooks/
      pre-push                 <- Blocks pushes to main
      pre-commit               <- Warns on big commits
      commit-msg               <- Enforces conventional commits
    scripts/
      setup-hooks.sh           <- Hook installer for teammates
    .gitattributes             <- Binary & lock file handling
    .github/
      pull_request_template.md <- PR template
  README.md
  LICENSE
```

## Want More?

If you want the full Claude Code collaboration setup — AI hooks, 9 portable skills, built-in courses, onboarding guide — check out [big-gulps-huh](https://github.com/newbynewbynewbz/big-gulps-huh).

## License

MIT — take it, use it, share it.
