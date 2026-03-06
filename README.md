# git-shit

Level up any repo's git setup in 60 seconds. Hooks, conventional commits, PR workflow, the works.

Also includes the full `/big-gulps-huh` scaffolder for setting up Claude Code collaboration from scratch.

## Two Skills, Two Speeds

### `/git-shit` — Just the git stuff

Drop into any repo. No Claude Code knowledge needed. Gets you:

- **pre-push hook** — blocks direct pushes to main. PR-only workflow.
- **pre-commit hook** — warns when commits are over 200 lines. Keeps things atomic.
- **commit-msg hook** — enforces `feat:` / `fix:` / `docs:` prefixes. Searchable history.
- **.gitattributes** — binary handling, lock file merge strategy.
- **.gitignore** — language-aware standard ignores.
- **PR template** — consistent pull request format for the team.
- **setup-hooks.sh** — one command to install hooks after cloning.
- **audit mode** — check what's missing without changing anything.

```
# Copy the skill file
cp .claude/commands/git-shit.md YOUR_PROJECT/.claude/commands/

# Run it
claude /git-shit

# Or just audit what's missing
claude /git-shit audit
```

### `/big-gulps-huh` — The full setup

For someone joining a project with nothing on their computer. Sets up everything:

1. Git protection (calls `/git-shit`)
2. Claude Code hooks (`.env` blocker, console sentinel, type assertion detector, async safety, file size warnings)
3. 9 portable skills (`/health`, `/preflight`, `/code-review`, `/deep-review`, `/retro`, `/future-feature`, `/ready-to-commit`, `/learn`, `/vibes`)
4. CLAUDE.md skeleton with TODOs
5. Big Gulps Guide — onboarding doc that actually explains things

Has a tutorial mode that teaches each layer as it scaffolds, and tone presets for the guide (sarcastic / professional / minimal).

```
# Copy both skill files
cp .claude/commands/git-shit.md YOUR_PROJECT/.claude/commands/
cp .claude/commands/big-gulps-huh.md YOUR_PROJECT/.claude/commands/

# Run the full setup
claude /big-gulps-huh

# Or with tutorial mode
claude /big-gulps-huh tutorial
```

## Quick Start (No Skill Runner)

Don't use Claude Code? Just copy the files directly:

```bash
# Clone this repo
git clone https://github.com/newbynewbynewbz/git-shit.git

# Copy git hooks to your project
cp git-shit/template/git-hooks/* YOUR_PROJECT/.git/hooks/
chmod +x YOUR_PROJECT/.git/hooks/*

# Copy the setup script
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
├── .claude/commands/
│   ├── git-shit.md              ← The standalone git skill
│   └── big-gulps-huh.md        ← The full collaboration scaffolder
├── template/                    ← Pre-built files (copy directly)
│   ├── git-hooks/
│   │   ├── pre-push             ← Blocks pushes to main
│   │   ├── pre-commit           ← Warns on big commits
│   │   └── commit-msg           ← Enforces conventional commits
│   ├── scripts/
│   │   ├── setup-hooks.sh       ← Hook installer for teammates
│   │   ├── check-console-log.sh ← Console statement detector
│   │   ├── check-as-any.sh      ← Type assertion detector
│   │   ├── check-async-safety.sh← Unguarded promise detector
│   │   └── check-file-size.sh   ← Large file detector
│   ├── .claude/commands/        ← 9 portable skills
│   │   ├── health.md
│   │   ├── preflight.md
│   │   ├── code-review.md
│   │   ├── deep-review.md
│   │   ├── ready-to-commit.md
│   │   ├── retro.md
│   │   ├── future-feature.md
│   │   ├── learn.md
│   │   └── vibes.md
│   ├── .github/
│   │   └── pull_request_template.md
│   ├── docs/
│   │   └── BIG_GULPS_GUIDE.md   ← Onboarding guide
│   ├── CLAUDE.md                ← Project config skeleton
│   └── .gitattributes           ← Binary & lock file handling
└── README.md
```

## Why This Exists

This came out of building [Pahu Hau](https://github.com/newbynewbynewbz/pahu-hau), a pantry management app for West Side Oahu families. After months of development with ~38 skills, 10 hooks, and a full CLAUDE.md system, friends and family wanted to help but needed guardrails so they couldn't break things, plus the best tools so they'd be productive day one.

The mission is simple: actually help people. Not give the appearance of helping. Actually help.

`/git-shit` is the git layer extracted and generalized for any project.
`/big-gulps-huh` is the full collaboration setup for anyone starting from zero.

## License

MIT — take it, use it, share it.
