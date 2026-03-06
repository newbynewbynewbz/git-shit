---
name: big-gulps-huh
description: Full zero-to-hero Claude Code collaboration setup — git protection, AI hooks, portable skills, CLAUDE.md skeleton, and a guide that actually explains things. For someone joining the project with nothing.
argument: "[path|new <name>|guide|tutorial|guide --tone <preset>]"
model-hint: opus
---

# Big Gulps, Huh? — Claude Code Collaboration Scaffolder

## Arguments

| Input | Action |
|-------|--------|
| *(empty)* | Scaffold into current working directory |
| `<path>` | Scaffold into specified project path |
| `new <name>` | Create new dir + `git init` + scaffold |
| `guide` | Just regenerate the Big Gulps Guide |
| `tutorial` | Scaffold WITH step-by-step teaching — pauses between layers to explain what each thing does and why |
| `guide --tone pro` | Regenerate guide in professional tone |
| `guide --tone minimal` | Regenerate guide in minimal bullet-point tone |

## Step 1: Detect Context

```
- Is this a git repo? (`git rev-parse --git-dir`)
- Does CLAUDE.md already exist?
- Does `.claude/commands/` already have skills?
- Does `.claude/settings.local.json` already exist?
```

If `new <name>` argument: create directory, `cd` into it, `git init`.
If `<path>` argument: verify it exists and `cd` into it.
If `guide` argument: skip to Step 8 (Big Gulps Guide generation only).
If `guide --tone pro` or `guide --tone minimal`: skip to Step 8 with tone preset.
If `tutorial` argument: set `$TUTORIAL_MODE=true` — same scaffold flow but with teaching pauses between each layer (see Tutorial Mode section below).

If CLAUDE.md or settings.local.json already exist, use AskUserQuestion to confirm overwrite.

## Step 2: Ask Stack Questions

Use AskUserQuestion to gather project context:

**Question 1 — Language:**
- TypeScript (Recommended)
- Python
- Go
- Rust
- Other

**Question 2 — Test runner:**
- Jest (Recommended for TS)
- Vitest
- Pytest
- Go test
- Cargo test
- Other

**Question 3 — Linter/type checker:**
- tsc + ESLint (Recommended for TS)
- Pyright + Ruff
- golangci-lint
- Clippy
- Other

**Question 4 — Package manager:**
- npm (Recommended)
- bun
- yarn
- pnpm
- pip/uv
- cargo
- go modules
- Other

Store answers as `$LANG`, `$TEST_CMD`, `$LINT_CMD`, `$PKG_MGR`.

**Question 5 — Guide tone:**
- Sarcastic (Recommended) — dry humor, roasts, "because someone did this" explanations
- Professional — same content, straight delivery, no jokes, corporate-safe
- Minimal — just the facts, bullet points only, no prose

Store as `$TONE`. Default to Sarcastic if user skips.

Derive file extensions from language:
- TypeScript → `*.ts|*.tsx`
- Python → `*.py`
- Go → `*.go`
- Rust → `*.rs`

## Step 3: Git Protection (via `/git-shit`)

Run `/git-shit` to scaffold the full git protection layer. This is a standalone skill that handles all git hooks, .gitattributes, PR template, and setup script. See `git-shit.md` for full details.

If `/git-shit` is not available (e.g., running outside this repo), fall back to creating all 3 hooks + setup script + .gitattributes inline. Use `chmod +x` on hooks after writing.

### `.git/hooks/pre-push`

```bash
#!/bin/bash
# Pre-push hook: Require PRs for main
# Blocks direct pushes to main — forces PR workflow
# Bypass: git push --no-verify (emergencies only)

BRANCH=$(git branch --show-current)
REMOTE="$1"

while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_ref" = "refs/heads/main" ] && [ "$BRANCH" = "main" ]; then
    if echo "$local_ref" | grep -q "refs/tags/"; then
      continue
    fi

    echo ""
    echo "🛑 Direct push to main blocked"
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

exit 0
```

### `.git/hooks/pre-commit`

```bash
#!/bin/bash
# Pre-commit hook: Commit size warning
# Non-blocking warning when staged changes exceed threshold

WARN_THRESHOLD=200

INSERTIONS=$(git diff --cached --numstat | awk '{sum+=$1} END{print sum+0}')

if [ "$INSERTIONS" -gt "$WARN_THRESHOLD" ]; then
  echo ""
  echo "⚠️  Commit size warning: $INSERTIONS insertions (threshold: $WARN_THRESHOLD)"
  echo ""
  echo "  Staged files:"
  git diff --cached --stat | tail -1
  echo ""
  echo "  Consider splitting into smaller atomic commits."
  echo "  Ask: 'Is this truly ONE logical change?'"
  echo ""
fi

exit 0
```

### `.git/hooks/commit-msg`

```bash
#!/bin/bash
# Commit-msg hook: Enforce conventional commit prefixes
# Valid: feat: fix: refactor: docs: test: chore: style: perf: ci: build: revert:
# Scopes optional: feat(auth): fix(api):

MSG_FILE="$1"
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

echo ""
echo "🛑 Commit message rejected — missing conventional prefix"
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
exit 1
```

### `scripts/setup-hooks.sh`

```bash
#!/bin/bash
# One-command hook installer for new cloners
# Run: bash scripts/setup-hooks.sh

HOOK_DIR=".git/hooks"

if [ ! -d ".git" ]; then
  echo "❌ Not a git repository. Run from project root."
  exit 1
fi

for hook in pre-push pre-commit commit-msg; do
  if [ -f "$HOOK_DIR/$hook" ]; then
    echo "✅ $hook already installed"
  else
    echo "❌ $hook missing — check your .git/hooks/ directory"
  fi
done

chmod +x "$HOOK_DIR"/pre-push "$HOOK_DIR"/pre-commit "$HOOK_DIR"/commit-msg 2>/dev/null
echo ""
echo "Done. All hooks are executable."
```

### `.gitattributes`

```
# Images — binary, no text diffs
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.webp binary
*.ico binary
*.svg text

# Fonts — always binary
*.ttf binary
*.otf binary
*.woff binary
*.woff2 binary

# Lock files — don't manually merge
package-lock.json -diff merge=ours
yarn.lock -diff merge=ours
bun.lockb binary
Cargo.lock -diff merge=ours

# Auto-normalize line endings
* text=auto
```

After writing all hooks, run: `chmod +x .git/hooks/pre-push .git/hooks/pre-commit .git/hooks/commit-msg`

## Step 4: Scaffold Claude Code Hooks

Write `.claude/settings.local.json` with hooks wired to the check scripts from Step 5.

Adapt the file extension patterns and project root check based on `$LANG`:
- TypeScript: `*.ts|*.tsx`, skip `__tests__/`, `__mocks__/`
- Python: `*.py`, skip `tests/`, `__pycache__/`
- Go: `*.go`, skip `*_test.go`
- Rust: `*.rs`, skip `tests/`

The settings.local.json structure:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash($PKG_MGR:*)",
      "Bash(node:*)",
      "Bash(npx:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(wc:*)",
      "Bash(chmod:*)",
      "Bash(bash:*)",
      "Bash(echo:*)",
      "Bash(mv:*)",
      "Bash(tree:*)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/check-console-log.sh",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "bash scripts/check-as-any.sh",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "bash scripts/check-async-safety.sh",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "bash scripts/check-file-size.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo \"$TOOL_INPUT\" | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))\" 2>/dev/null); case \"$FILE_PATH\" in */.env|*/.env.*) echo 'BLOCKED: .env files are immutable. Edit .env manually to prevent accidental credential exposure.' >&2; exit 2;; *) exit 0;; esac",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "echo \"Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')\" && echo \"Uncommitted: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files\" && echo \"Tip: Run /health for full project status\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Language-specific adjustments:**
- For Python: replace `check-as-any.sh` with `check-type-ignore.sh` (same pattern but greps for `# type: ignore`)
- For Go: omit `check-as-any.sh` (no equivalent), keep console/async/size
- For Rust: omit `check-as-any.sh`, omit `check-console-log.sh` (Rust uses `println!` which clippy handles)
- Add language-specific permission entries (e.g., `Bash(python3:*)`, `Bash(go:*)`, `Bash(cargo:*)`)

## Step 5: Scaffold Check Scripts

Write 4 portable check scripts to `scripts/`. Each uses the same stdin JSON pattern.

**IMPORTANT:** Replace the project root check (`*/pahu-hau/*`) with a generic check. Use the project's directory name dynamically. For the generalized version, remove the project root filter entirely — the file extension and test exclusion filters are sufficient.

### `scripts/check-console-log.sh`

Adapt from the template in Step 4 notes. For each language:
- **TypeScript:** grep for `console.(log|warn|error|info|debug|trace)(`
- **Python:** grep for `print(` (excluding test files)
- **Go:** grep for `fmt.Print` (excluding test files)
- **Rust:** grep for `println!` or `dbg!`

Core pattern for all:

```bash
#!/bin/bash
# Hook: Console/Print Statement Sentinel
# Warns on debug print statements in production code (non-blocking)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# --- LANGUAGE FILTER (adapt per $LANG) ---
case "$FILE_PATH" in
  $EXT_PATTERN) ;;
  *) exit 0 ;;
esac

# --- SKIP TEST/CONFIG FILES ---
case "$FILE_PATH" in
  */__tests__/*|*/__mocks__/*|*.test.*|*.spec.*|*/jest.setup*|*/.claude/*|*/scripts/*) exit 0 ;;
esac

MATCHES=$(grep -nE '$CONSOLE_PATTERN' "$FILE_PATH" 2>/dev/null | grep -v "//.*console\." | head -5)

if [ -n "$MATCHES" ]; then
  echo ""
  echo "--- Warning: Debug Print Statements ---"
  echo "File: $(basename "$FILE_PATH")"
  echo ""
  echo "$MATCHES"
  echo ""
  echo "Remove debug statements before committing."
  echo "----------------------------------------"
  echo ""
fi

exit 0
```

### `scripts/check-as-any.sh`

TypeScript only. Greps for `\bas any\b`. Same stdin/filter pattern. Skip for Python/Go/Rust — instead:
- **Python:** Write `check-type-ignore.sh` that greps for `# type: ignore`
- **Go/Rust:** Skip this script entirely

### `scripts/check-async-safety.sh`

Generalized version — remove the Pahu Hau-specific function names from Check 1. Keep only:
- **Check 1 (generic):** `AsyncStorage.(setItem|removeItem)` (for JS/TS projects). For Python: look for bare `asyncio.create_task(` without error handling.
- **Check 2 (universal):** `.then(` chains without `.catch()` within 30 lines (JS/TS only)
- For Go/Rust: skip this script (the compiler handles most of this)

### `scripts/check-file-size.sh`

100% generic — copy as-is but remove the project root filter (`*/pahu-hau/*`). Works for all languages. Keep the 500-line threshold.

## Step 6: Scaffold 9 Portable Skills

Write generalized versions of these skills to `.claude/commands/`. For each, strip all Pahu Hau-specific references and replace with generic equivalents or `$PROJECT`-style placeholders.

### Skill 1: `future-feature.md`

**Keep:** Full 7-step pipeline (collect sources → extract → deduplicate → tier → backlog → build plan → report)
**Generalize:**
- Source paths: replace with `docs/reviews/`, `docs/episodes/`, `docs/reports/`
- Feature tiers: keep Tier 1-4 system but remove Pahu Hau persona names
- Output: `docs/future-features/FEATURE_BACKLOG.md` and `BUILD_PLAN.md`
- Extraction: generic naming `review_[N].md`, `report_[N].md`
- Remove: specific persona extraction rules, Pahu Hau file paths

### Skill 2: `ready-to-commit.md`

**Keep:** File-count routing, category detection, preflight + retro chain
**Generalize:**
- Categories: COMPONENT, SERVICE, TYPE, TEST, CONFIG, OTHER (remove STORE, PARSER, RECIPE_SEED)
- Paths: generic `src/**`, `lib/**`, `app/**`, `components/**`, `types/**`, `tests/**`
- Skill chain: `/code-review` → `/preflight` → `/retro` (remove `/audit-sync`, `/guard-parser`)
- Remove: `.claude/.audit-state.json` cache (too project-specific), specific test counts

### Skill 3: `code-review.md`

**Keep:** Multi-agent routing (<=3 files single, >3 multi-agent), security checks, performance patterns
**Generalize:**
- Remove: theme token compliance, Zustand patterns, Firebase checks, tab bar dimensions
- Keep: unused imports, dead code, error handling, type safety, accessibility, naming conventions
- Add: generic "design system compliance" placeholder

### Skill 4: `deep-review.md`

**Keep:** 5-agent parallel structure (Architecture, Security, Performance, Correctness, DX)
**Generalize:**
- Remove: theme tokens, Zustand patterns, Firebase scoping, tab bar height
- Keep: parallel agent structure, severity ratings, fingerprinting
- Replace domain checklists with generic equivalents

### Skill 5: `preflight.md`

**Keep:** 5-check structure (types, tests, hardcoded values, console.log, listener cleanup)
**Generalize:**
- Type check: `$LINT_CMD` instead of `npx tsc --noEmit`
- Test: `$TEST_CMD` instead of `npm test`
- Hardcoded values: generic "magic numbers / hardcoded strings" instead of COLORS/SPACING
- Console.log: adapt pattern per language
- Listener cleanup: generic "resource cleanup" instead of Firebase-specific

### Skill 6: `health.md`

**Keep:** Types, tests, deps, TODOs, large files, summary report
**Generalize:**
- Commands: `$LINT_CMD`, `$TEST_CMD`, `$PKG_MGR outdated`, `$PKG_MGR audit`
- Directories: `src/`, `lib/`, `app/`, `components/` (generic)
- Remove: `npx expo-doctor`
- Add: configurable directory list comment

### Skill 7: `retro.md`

**Keep:** 4-agent parallel structure (Lessons, Skills Auditor, CLAUDE.md Freshness, Workflow Efficiency)
**Generalize:**
- Replace `pahu-hau/` with project root
- Remove: specific config paths, MEMORY.md 200-line limit reference
- Keep: recent commits analysis, skill audit, CLAUDE.md drift detection, workflow metrics

### Skill 8: `learn.md`

**Keep:** Interactive tutor, predict-then-reveal, Socratic flow, mentor system, progress tracking
**Generalize:**
- Mentor names: keep the 3-mentor system but use generic names (The Professor, The Practitioner, The Philosopher) — let users customize
- Course paths: `docs/courses/<topic>/`
- Remove: Hawaiian references, specific project paths
- Keep: COURSE.md + questions.json + progress.json structure

### Skill 9: `vibes.md`

**Copy directly** — 100% generic already. No changes needed.

## Step 7: Generate CLAUDE.md Skeleton

Write a `CLAUDE.md` with pre-filled universal sections and TODO markers:

```markdown
# [Project Name] — CLAUDE.md

## Usage Rules

### For Humans
- Always work on feature branches — never commit directly to main
- Use conventional commit messages: `type(scope): description`
- Keep commits atomic — one logical change per commit
- Run `/preflight` before pushing

### For Claude
- Read files before editing — never guess at existing code
- Run type checker after every edit session
- Never edit .env files
- Prefer editing existing files over creating new ones
- Keep files under 500 lines — extract when they grow

## Verification Checklist
- [ ] `$LINT_CMD` passes with 0 errors
- [ ] `$TEST_CMD` passes
- [ ] No `console.log` in production code <!-- TODO: adapt for your language -->
- [ ] No `as any` type assertions <!-- TODO: adapt for your language -->
- [ ] New files have tests

## Clarification Protocol
When a request is ambiguous, Claude MUST ask before implementing:
1. "Which approach do you prefer?" (with trade-offs)
2. "Should this be temporary or permanent?"
3. "What's the expected behavior for edge case X?"
Never guess on architecture decisions. A 30-second question saves a 30-minute rewrite.

## Hook Reference
| Hook | Type | Trigger | What It Does |
|------|------|---------|--------------|
| .env blocker | Blocking | PreToolUse (Edit/Write) | Prevents editing .env files |
| Console sentinel | Warning | PostToolUse (Edit/Write) | Warns on debug print statements |
| Type assertion detector | Warning | PostToolUse (Edit/Write) | Warns on type safety bypasses |
| Async safety | Warning | PostToolUse (Edit/Write) | Warns on unguarded promises |
| File size | Warning | PostToolUse (Edit/Write) | Warns on 500+ line files |
| Session greeting | Info | SessionStart | Shows branch + uncommitted count |

## Tech Stack
<!-- TODO: Fill in your stack -->
| Layer | Technology |
|-------|-----------|
| Language | $LANG |
| Framework | TODO |
| Test Runner | $TEST_CMD |
| Linter | $LINT_CMD |
| Package Manager | $PKG_MGR |

## Commands
<!-- TODO: Fill in your project commands -->
| Command | What |
|---------|------|
| `$TEST_CMD` | Run tests |
| `$LINT_CMD` | Type check / lint |
| TODO | TODO |

## File Structure
<!-- TODO: Map your project structure -->
```
src/           # Source code
tests/         # Test files
scripts/       # Build & check scripts
docs/          # Documentation
.claude/       # Claude Code config & skills
```

## Code Patterns
<!-- TODO: Document your patterns -->
- Components: TODO
- Services: TODO
- State management: TODO
- Error handling: TODO

## Common Gotchas
- `.env` files are protected — edit manually, never through Claude
- Commits over 200 lines trigger a warning — split if possible
- Direct pushes to main are blocked — use PR workflow
<!-- TODO: Add project-specific gotchas -->

## Custom Skills
| Skill | What It Does |
|-------|-------------|
| `/health` | Full project health report |
| `/preflight` | Pre-push verification checks |
| `/code-review` | Multi-agent code review |
| `/deep-review` | 5-agent deep review |
| `/retro` | Post-session retrospective |
| `/future-feature` | Feature extraction & backlog management |
| `/ready-to-commit` | Smart commit preparation |
| `/learn` | Interactive codebase tutor |
| `/vibes` | Daily motivation & focus |
```

Replace `$LANG`, `$TEST_CMD`, `$LINT_CMD`, `$PKG_MGR` with actual values from Step 2.

## Tutorial Mode

When `$TUTORIAL_MODE=true`, insert teaching pauses between each layer. After writing each layer's files, output an explanation block and wait for user acknowledgment before continuing.

### After Layer 1 (Git Hooks) — pause and explain:

```
📚 LAYER 1: Git Protection
===========================

I just created 3 git hooks in .git/hooks/. Here's what each one does:

PRE-PUSH — The Bouncer
  Blocks you from pushing directly to main. Why? Because main is production.
  Every change goes through a branch → PR → review → merge cycle.
  Think of it like a "measure twice, cut once" rule for code.

PRE-COMMIT — The Friendly Nudge
  Warns (doesn't block) when your commit has 200+ new lines.
  Big commits are hard to review, hard to revert, and hard to understand.
  If you're over 200 lines, ask: "Is this really ONE change?"

COMMIT-MSG — The Grammar Police
  Requires commit messages like "feat: add login" or "fix(api): null check".
  This isn't pedantic — it makes `git log` searchable and changelogs automatic.
  Six months from now, "feat:" vs "fix:" tells you exactly what happened.

Also created:
  .gitattributes     — tells git how to handle binary files (images, fonts, locks)
  scripts/setup-hooks.sh — one-command hook installer for teammates

💡 Key concept: Git hooks run automatically before/after git operations.
   They live in .git/hooks/ and are NOT committed to the repo (each clone
   needs to run setup-hooks.sh to install them).

Ready for the next layer? [continue]
```

### After Layer 2 (Claude Code Hooks) — pause and explain:

```
📚 LAYER 2: Claude Code Hooks
===============================

I just created .claude/settings.local.json with AI guardrails.

These are different from git hooks — they run inside Claude Code itself,
checking every file edit in real-time:

.ENV BLOCKER (Blocking — actually prevents the action)
  Claude literally cannot edit .env files. This protects credentials
  from appearing in AI conversation logs or being accidentally committed.

CONSOLE SENTINEL (Warning — lets it through but yells)
  Flags console.log/warn/error in production code. Debug statements
  in production leak info and look unprofessional.

TYPE ASSERTION DETECTOR (Warning)
  Catches `as any` — TypeScript's escape hatch that defeats the
  whole purpose of using TypeScript.

ASYNC SAFETY (Warning)
  Finds .then() chains without .catch(). Unhandled promise rejections
  cause silent failures — your app breaks and nobody knows why.

FILE SIZE (Warning)
  Flags files over 500 lines. Big files = hard to test, hard to
  understand, hard to maintain. Extract early, extract often.

SESSION GREETING (Info — just shows status)
  Shows your current branch and uncommitted file count on startup.
  Prevents the "wait, am I on main?" panic.

💡 Key concept: "Blocking" hooks prevent the action. "Warning" hooks
   let it through but show a message. You decide which rules are hard
   stops vs gentle reminders.

Ready for the next layer? [continue]
```

### After Layer 3 (Check Scripts) — pause and explain:

```
📚 LAYER 3: Check Scripts
===========================

I just created 4 shell scripts in scripts/. These are the engines
behind the Claude Code hooks from Layer 2.

How they work:
  1. Claude edits a file
  2. The hook triggers and pipes the edit info to the script
  3. The script reads the file path from JSON stdin
  4. Checks if it's a source file (not test, not config)
  5. Runs a grep pattern looking for problems
  6. Prints a warning if found, stays silent if clean

This pattern is reusable — you can copy any of these scripts and
change the grep pattern to detect whatever matters to your project
(hardcoded URLs, TODO comments, deprecated APIs, etc.).

💡 Key concept: All 4 scripts exit 0 (non-blocking). They warn but
   never prevent. If you want a hard stop, change to exit 1. The .env
   blocker in Layer 2 uses exit 2 — that's the blocking signal.

Ready for the next layer? [continue]
```

### After Layer 4 (Skills) — pause and explain:

```
📚 LAYER 4: Portable Skills
=============================

I just installed 9 skills in .claude/commands/. These are like
keyboard shortcuts for complex workflows.

The ones you'll use most:
  /health     — "Is my project broken?" in one command
  /preflight  — Run before every push (types + tests + lint)
  /vibes      — Not a joke. Productivity science. Try it Monday.

The power tools:
  /code-review  — Spawns multiple AI agents to review your code
  /deep-review  — 5 parallel agents for serious changes
  /retro        — Captures what you learned after a work session

The planning tools:
  /future-feature  — Extracts feature ideas from docs/reviews
  /ready-to-commit — Categorizes your changes and suggests commit messages
  /learn           — Interactive tutor that teaches YOUR codebase

💡 Key concept: Skills are markdown files that tell Claude HOW to
   do something. They're like prompts with structure. You can read
   them, edit them, and create new ones for your own workflows.

Ready for the next layer? [continue]
```

### After Layer 5 (CLAUDE.md + Guide) — final explanation:

```
📚 LAYER 5: Documentation
===========================

Two files:

CLAUDE.md — Your project's constitution
  This is the single most important file for Claude Code productivity.
  Every section you fill in makes Claude smarter about YOUR project.
  The TODOs aren't optional — they're the difference between "generic
  AI help" and "AI that knows your codebase."

  Priority TODOs (fill these first):
    1. Tech Stack — what you're building with
    2. File Structure — where things live
    3. Code Patterns — how you write code
    4. Common Gotchas — mistakes to avoid

docs/BIG_GULPS_GUIDE.md — The onboarding guide
  Share this with anyone joining the project. It explains everything
  we just set up in plain language with DYOR links for deeper reading.

💡 Key concept: CLAUDE.md is read by Claude at the start of every
   conversation. It's persistent context. The more accurate it is,
   the less time you spend correcting Claude's assumptions.

🎓 Tutorial complete! You now understand all 5 layers.
   Next: Fill in the CLAUDE.md TODOs, then try /health.
```

Use AskUserQuestion with "Continue to next layer?" between each pause. If user says "skip" or "just finish", drop out of tutorial mode and complete remaining layers without pauses.

## Step 8: Generate Big Gulps Guide

Write `docs/BIG_GULPS_GUIDE.md` using the `$TONE` preset selected in Step 2.

### Tone: Sarcastic (default)

Use these tone rules:
- Dry humor, not mean
- Every rule gets a "why" that's slightly embarrassing ("because someone did this")
- DYOR tags link to real documentation
- Assume the reader is smart but lazy
- Channel the energy of a friend who's helping you move but roasting your furniture choices

### Tone: Professional

Use these tone rules:
- Clear, direct, no humor
- Every rule gets a business justification ("reduces incident response time")
- DYOR tags link to real documentation
- Assume the reader is an experienced developer who values efficiency
- Channel the energy of well-written internal engineering docs

Adjustments from sarcastic template:
- Replace the Lloyd Christmas quote with: *"A practical guide to collaborative development with Claude Code."*
- Replace "more safety nets than a Cirque du Soleil performer" → "a comprehensive set of development guardrails"
- Replace "fixed stuff is not a commit message, it's a cry for help" → "Descriptive prefixes enable automated changelog generation and searchable history"
- Replace "that's not a commit, that's a hostage situation" → "Large commits increase review difficulty and revert risk"
- Replace "how you end up on Hacker News for the wrong reasons" → "Credentials in conversation logs pose a security risk"
- Replace hook table "Why It Exists (Because Someone Did This)" column → "Rationale"
- Replace sarcastic hook reasons with professional ones (e.g., "Pushed untested code to main at 2am" → "Enforces code review before integration with the production branch")
- Replace FAQ answers ("No." / "No." / "No.") → professional explanations
- Replace "Welcome to the guardrail life" → "Your development environment is configured"
- Keep all DYOR links, skill tables, and quick start steps identical

### Tone: Minimal

Use these tone rules:
- No prose, no personality, no explanations
- Bullet points and tables only
- Section headers + content, nothing else
- Assume the reader will look things up if they need to

Adjustments from sarcastic template:
- No epigraph/quote
- No "What Just Happened" narrative — replace with 1-line summary
- Rules section: just the rule name + the hook that enforces it + DYOR link
- Skills table: keep as-is (already minimal)
- Hooks table: keep as-is but drop the "Because Someone Did This" column — just "What" and "Why"
- No CLAUDE.md explanation prose — just "Fill in the TODOs in CLAUDE.md"
- Quick start: numbered list only, no commentary
- No FAQ
- No "One More Thing"
- Footer: just "Generated by `/big-gulps-huh`"

**Template:**

```markdown
# The Big Gulps Guide

> "Big gulps, huh? Welp, see ya later!" — Lloyd Christmas, professional optimist

*A sarcastic but genuinely helpful guide to not breaking things.*

---

## What Just Happened

You (or someone who cares about you) just ran `/big-gulps-huh` and scaffolded a complete Claude Code collaboration setup into this project. That means git hooks, AI guardrails, portable skills, and a CLAUDE.md constitution. You now have more safety nets than a Cirque du Soleil performer.

---

## The Rules

### 1. Never Push to Main

The `pre-push` hook will block you. Main is sacred. It's where working code lives. You work on branches, you make PRs, you get them merged. This is not negotiable.

**DYOR:** [Git branching strategies](https://docs.github.com/en/get-started/quickstart/github-flow)

### 2. Conventional Commits or Go Home

Every commit message needs a prefix: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, etc. The `commit-msg` hook enforces this. "fixed stuff" is not a commit message, it's a cry for help.

**DYOR:** [Conventional Commits spec](https://www.conventionalcommits.org/)

### 3. Keep Commits Small

The `pre-commit` hook warns you at 200+ lines. If your commit touches 47 files, that's not a commit, that's a hostage situation. One logical change per commit.

**DYOR:** [Atomic commits](https://www.pauline-vos.nl/atomic-commits/)

### 4. Don't Touch .env Files Through Claude

The `.env` blocker hook will physically prevent it. Credentials in AI chat history is how you end up on Hacker News for the wrong reasons.

**DYOR:** [12-Factor App — Config](https://12factor.net/config)

---

## The Skills (Your New Superpowers)

| Skill | What It Does | When to Use It |
|-------|-------------|----------------|
| `/health` | Runs types, tests, deps, TODOs, file sizes | "Is everything still working?" |
| `/preflight` | Pre-push verification suite | Before every push. Every. Single. One. |
| `/code-review` | Multi-agent code review | After finishing a feature, before PR |
| `/deep-review` | 5-agent parallel deep review | For important changes or new architecture |
| `/retro` | Post-session retrospective | End of a work session — captures lessons |
| `/future-feature` | Extract & prioritize feature ideas | After reviews, user feedback, brainstorms |
| `/ready-to-commit` | Smart commit prep with category detection | When you're ready to commit (duh) |
| `/learn` | Interactive codebase tutor | When you're new or exploring unfamiliar code |
| `/vibes` | Daily motivation & focus helper | When you need a productivity boost |

**Pro tip:** The minimum viable workflow is `/preflight` before pushing and `/health` when things feel off. Everything else is bonus XP.

---

## The Hooks (Things That Yell at You)

| Hook | What It Checks | Why It Exists (Because Someone Did This) |
|------|---------------|------------------------------------------|
| pre-push | Direct pushes to main | Pushed untested code to main at 2am. Production went down. |
| pre-commit | Commit size > 200 lines | Made a 3,000-line commit called "updates". Nobody could review it. Ever. |
| commit-msg | Conventional commit prefix | Wrote "asdf" as a commit message. Six months later, needed to find that change. |
| .env blocker | .env file edits via Claude | AI assistant helpfully committed AWS keys to a public repo. |
| Console sentinel | console.log in prod code | Left `console.log("here")` in production. Users saw it. |
| Type assertion detector | `as any` usage | Cast everything to `any` to "fix" type errors. Created 47 runtime errors. |
| Async safety | Unguarded promises | Forgot `.catch()`. App silently failed. Users saw a blank screen for 3 days. |
| File size | Files over 500 lines | Created a 2,400-line "utils.ts". It's still haunted. |
| Session greeting | Branch + uncommitted files | Started coding on main. Didn't notice for 2 hours. |

---

## The CLAUDE.md (Your Project's Constitution)

The `CLAUDE.md` file has TODO markers. **Fill them in.** This is not optional busywork — it's what makes Claude actually useful for your specific project instead of giving you generic Stack Overflow answers.

The sections that matter most:
1. **Tech Stack** — so Claude knows what you're working with
2. **File Structure** — so Claude finds things without asking
3. **Code Patterns** — so Claude writes code that looks like yours
4. **Common Gotchas** — so Claude doesn't repeat your past mistakes

Think of it as onboarding docs, except the new hire is an AI that reads really fast and has zero institutional knowledge.

---

## Quick Start

1. **Read this guide** *(you're doing it, gold star)*
2. **Fill in CLAUDE.md TODOs** — Tech Stack, File Structure, Code Patterns
3. **Run `bash scripts/setup-hooks.sh`** to verify hooks are installed
4. **Try `/health`** to see your project's current status
5. **Make a test branch:** `git checkout -b test/my-first-branch`
6. **Make a small change and commit:** `git commit -m "test: verify hook setup"`
7. **Run `/preflight`** before pushing

If all 7 steps work, you're ready. Welcome to the guardrail life.

---

## FAQ

**Q: Can I push to main?**
A: No.

**Q: But what if—**
A: No.

**Q: What if it's really small and I promise it's fine?**
A: `git push --no-verify` exists for genuine emergencies. If you use it for convenience, the hooks will judge you silently.

**Q: I got a commit message error. What do I do?**
A: Start your message with a type: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `style:`, `perf:`, `ci:`, `build:`, or `revert:`. That's it. That's the whole thing.

**Q: Claude keeps warning me about console.log. Is it broken?**
A: It's working perfectly. Remove your console.log statements. Use a proper logger.

**Q: What's `/vibes` actually for?**
A: Productivity science disguised as fun. Try it on a Monday morning.

**Q: This is a lot of setup. Is it worth it?**
A: You'll thank us the first time a hook catches something at 2am that would have been a production incident at 8am.

---

## One More Thing

This setup is a starting point, not a straitjacket. As your project grows:
- Add project-specific hooks (design token enforcement, API validation, etc.)
- Create custom skills for repetitive workflows
- Update CLAUDE.md as patterns evolve
- Run `/retro` regularly to capture what you've learned

The goal isn't perfection — it's fewer "oh no" moments and more "oh nice" moments.

---

*Generated by `/big-gulps-huh` — your friendly neighborhood scaffolder.*
*DYOR: Do Your Own Research. The links above are starting points, not gospel.*
```

## Step 9: Final Report

After scaffolding, print a summary:

```
✅ Big Gulps scaffolding complete!

  Git Hooks:
    .git/hooks/pre-push       — PR-only workflow enforced
    .git/hooks/pre-commit     — 200-line commit warning
    .git/hooks/commit-msg     — Conventional commits required

  Claude Code Hooks:
    .claude/settings.local.json — 6 hooks wired

  Check Scripts:
    scripts/check-console-log.sh
    scripts/check-as-any.sh      (or language equivalent)
    scripts/check-async-safety.sh
    scripts/check-file-size.sh

  Skills (9):
    .claude/commands/future-feature.md
    .claude/commands/ready-to-commit.md
    .claude/commands/code-review.md
    .claude/commands/deep-review.md
    .claude/commands/preflight.md
    .claude/commands/health.md
    .claude/commands/retro.md
    .claude/commands/learn.md
    .claude/commands/vibes.md

  Documentation:
    CLAUDE.md                    — Fill in the TODOs!
    docs/BIG_GULPS_GUIDE.md      — Share with your team

  Next steps:
    1. Fill in CLAUDE.md TODOs
    2. Run: bash scripts/setup-hooks.sh
    3. Try: /health
    4. Read: docs/BIG_GULPS_GUIDE.md
```
