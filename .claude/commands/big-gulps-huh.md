---
name: big-gulps-huh
description: Full zero-to-hero Claude Code collaboration setup — git protection, AI hooks, portable skills, CLAUDE.md skeleton, and a guide that actually explains things.
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
| `tutorial` | Scaffold with step-by-step teaching pauses between layers |
| `guide --tone pro` | Regenerate guide in professional tone |
| `guide --tone minimal` | Regenerate guide in minimal bullet-point tone |

## Step 1: Detect Context & Idempotency

```bash
git rev-parse --git-dir 2>/dev/null  # Is this a git repo?
```

Scan for existing scaffold files and report status:

| Layer | Files to check |
|-------|---------------|
| Git protection | `.git/hooks/pre-push`, `pre-commit`, `commit-msg`, `.gitattributes`, `scripts/setup-hooks.sh` |
| Claude Code hooks | `.claude/settings.local.json` |
| Check scripts | `scripts/check-console-log.sh`, `check-as-any.sh`, `check-async-safety.sh`, `check-file-size.sh` |
| Skills | `.claude/commands/health.md` (+ 8 others) |
| CLAUDE.md | `CLAUDE.md` |
| Guide | `docs/BIG_GULPS_GUIDE.md` |

Print a scan summary:

```
Scaffold scan:
  Git protection:  [✅ present | ❌ missing]
  Claude hooks:    [✅ present | ❌ missing]
  Check scripts:   [N/4 present]
  Skills:          [N/9 present]
  CLAUDE.md:       [✅ present | ❌ missing]
  Guide:           [✅ present | ❌ missing]
```

**Skip layers that are fully present.** For partially present layers, use AskUserQuestion: "Some [layer] files exist. Overwrite all, skip existing, or choose per file?"

If `new <name>`: create directory, `cd`, `git init`, scaffold everything.
If `guide` or `guide --tone <preset>`: skip to Step 8.
If `tutorial`: set `$TUTORIAL_MODE=true` — same flow with teaching pauses (see Tutorial Mode below).

## Step 2: Ask Stack Questions

Use AskUserQuestion to gather project context:

**Q1 — Language:**
- TypeScript (Recommended)
- Python
- Go
- Rust
- Other

**Q2 — Test runner:**
- Jest (Recommended for TS) / Vitest / Pytest / Go test / Cargo test / Other

**Q3 — Linter/type checker:**
- tsc + ESLint (Recommended for TS) / Pyright + Ruff / golangci-lint / Clippy / Other

**Q4 — Package manager:**
- npm (Recommended) / bun / yarn / pnpm / pip / uv / cargo / go modules / Other

**Q5 — Guide tone:**
- Sarcastic (Recommended) — dry humor, "because someone did this" explanations
- Professional — same content, straight delivery, corporate-safe
- Minimal — just the facts, bullet points only

Store as `$LANG`, `$TEST_CMD`, `$LINT_CMD`, `$PKG_MGR`, `$TONE`.

Derive extensions and exclusions:

| Language | `$EXT` | Test exclusions |
|----------|--------|----------------|
| TypeScript | `*.ts\|*.tsx` | `__tests__/`, `__mocks__/`, `*.test.*`, `*.spec.*` |
| Python | `*.py` | `tests/`, `test_*`, `*_test.py` |
| Go | `*.go` | `*_test.go` |
| Rust | `*.rs` | `tests/`, `*_test.rs` |

## Step 3: Git Protection

Delegate to `/git-shit`. Claude already has language, package manager, and branch answers from Step 2 — use those instead of re-asking.

If `/git-shit` is not available (running outside a repo that has it), write the 3 hooks + .gitattributes + setup-hooks.sh + .gitignore manually. The exact hook content is specified in the `git-shit.md` skill file — follow its Steps 3-6.

After this step, `.git/hooks/pre-push`, `pre-commit`, `commit-msg`, `.gitattributes`, `scripts/setup-hooks.sh`, and `.gitignore` should all exist.

## Step 4: Scaffold Claude Code Hooks

Write `.claude/settings.local.json` with permissions and hooks.

### Permissions by language

All languages get these base permissions:

```
WebSearch, Bash(git:*), Bash(gh:*), Bash(ls:*), Bash(find:*), Bash(grep:*),
Bash(cat:*), Bash(head:*), Bash(wc:*), Bash(chmod:*), Bash(bash:*),
Bash(echo:*), Bash(mv:*), Bash(tree:*)
```

Add language-specific entries:

| Language | Additional permissions |
|----------|----------------------|
| TypeScript | `Bash(node:*)`, `Bash(npx:*)`, `Bash(tsc:*)`, `Bash($PKG_MGR:*)` |
| Python | `Bash(python3:*)`, `Bash(pip:*)`, `Bash(pytest:*)`, `Bash(pyright:*)`, `Bash(ruff:*)` |
| Go | `Bash(go:*)`, `Bash(golangci-lint:*)` |
| Rust | `Bash(cargo:*)`, `Bash(rustc:*)` |

### Hook wiring

Which check scripts to wire per language:

| Language | Console | Type safety | Async | File size |
|----------|---------|-------------|-------|-----------|
| TypeScript | `check-console-log.sh` | `check-as-any.sh` | `check-async-safety.sh` | `check-file-size.sh` |
| Python | `check-print-stmt.sh` | `check-type-ignore.sh` | *(skip)* | `check-file-size.sh` |
| Go | `check-fmt-print.sh` | *(skip)* | *(skip)* | `check-file-size.sh` |
| Rust | *(skip — clippy)* | *(skip)* | *(skip)* | `check-file-size.sh` |

### settings.local.json template

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "Bash(git:*)", "Bash(gh:*)", "Bash(ls:*)", "Bash(find:*)",
      "Bash(grep:*)", "Bash(cat:*)", "Bash(head:*)", "Bash(wc:*)",
      "Bash(chmod:*)", "Bash(bash:*)", "Bash(echo:*)", "Bash(mv:*)",
      "Bash(tree:*)",
      "$LANG_SPECIFIC_PERMISSIONS"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "bash scripts/$CONSOLE_SCRIPT", "timeout": 5 },
          { "type": "command", "command": "bash scripts/$TYPE_SAFETY_SCRIPT", "timeout": 5 },
          { "type": "command", "command": "bash scripts/$ASYNC_SCRIPT", "timeout": 5 },
          { "type": "command", "command": "bash scripts/check-file-size.sh", "timeout": 5 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE_PATH=$(echo \"$TOOL_INPUT\" | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))\" 2>/dev/null); case \"$FILE_PATH\" in */.env|*/.env.*) echo 'BLOCKED: .env files are immutable. Edit manually.' >&2; exit 2;; *) exit 0;; esac",
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
            "command": "echo \"Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')\" && echo \"Uncommitted: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files\" && echo \"Tip: Run /health for project status\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Omit hook entries for scripts that don't apply to the chosen language** (see table above). Replace `$CONSOLE_SCRIPT`, `$TYPE_SAFETY_SCRIPT`, `$ASYNC_SCRIPT` with actual filenames, and `$LANG_SPECIFIC_PERMISSIONS` with the actual permission strings.

## Step 5: Scaffold Check Scripts

Write to `scripts/`. All scripts share the stdin JSON pattern for reading the edited file path from Claude Code hooks.

### `check-console-log.sh` (TypeScript version)

```bash
#!/bin/bash
# Console Statement Sentinel — warns on debug prints (non-blocking)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$FILE_PATH" in */__tests__/*|*/__mocks__/*|*.test.*|*.spec.*|*/jest.setup*|*/.claude/*|*/scripts/*) exit 0 ;; esac

MATCHES=$(grep -nE "console\.(log|warn|error|info|debug|trace)\(" "$FILE_PATH" 2>/dev/null | grep -v "//.*console\." | head -5)
if [ -n "$MATCHES" ]; then
  echo ""
  echo "--- Warning: Console Statements ---"
  echo "File: $(basename "$FILE_PATH")"
  echo "$MATCHES"
  echo "Remove before committing. Use a logger instead."
  echo "-----------------------------------"
fi
exit 0
```

**Python variant** (`check-print-stmt.sh`): Same structure. Match `*.py`, skip `tests/`/`test_*`/`conftest*`. Grep for `\bprint\(` excluding lines with `# noqa`.

**Go variant** (`check-fmt-print.sh`): Same structure. Match `*.go`, skip `*_test.go`. Grep for `fmt\.Print`.

### `check-as-any.sh` (TypeScript only)

```bash
#!/bin/bash
# Type Assertion Sentinel — warns on `as any` (non-blocking)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$FILE_PATH" in */__tests__/*|*/__mocks__/*|*.test.*|*.spec.*|*/.claude/*|*/scripts/*) exit 0 ;; esac

MATCHES=$(grep -nE '\bas any\b' "$FILE_PATH" 2>/dev/null | grep -v "//.*as any" | head -5)
if [ -n "$MATCHES" ]; then
  echo ""
  echo "--- Warning: \`as any\` Type Assertion ---"
  echo "File: $(basename "$FILE_PATH")"
  echo "$MATCHES"
  echo "Use proper types or \`unknown\` with type guards."
  echo "------------------------------------------"
fi
exit 0
```

**Python variant** (`check-type-ignore.sh`): Same structure. Match `*.py`. Grep for `# type: ignore` (without specific error codes in brackets — bare ignores are the problem).

**Go and Rust:** Skip this script entirely — their type systems don't have an equivalent escape hatch at this level.

### `check-async-safety.sh` (TypeScript only)

```bash
#!/bin/bash
# Async Promise Safety — warns on .then() without .catch() (non-blocking)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in *.ts|*.tsx) ;; *) exit 0 ;; esac
case "$FILE_PATH" in */__tests__/*|*/__mocks__/*|*.test.*|*.spec.*|*/.claude/*|*/scripts/*) exit 0 ;; esac

THEN_LINES=$(grep -nE '\.then\(' "$FILE_PATH" 2>/dev/null | head -10)
[ -z "$THEN_LINES" ] && exit 0

WARNINGS=""
while IFS= read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  END=$((LINE_NUM + 30))
  HAS_CATCH=$(sed -n "${LINE_NUM},${END}p" "$FILE_PATH" 2>/dev/null | grep -c '\.catch(')
  if [ "$HAS_CATCH" -eq 0 ]; then
    WARNINGS="${WARNINGS}${line}\n"
  fi
done <<< "$THEN_LINES"

if [ -n "$WARNINGS" ]; then
  echo ""
  echo "--- Warning: Unguarded Async ---"
  echo "File: $(basename "$FILE_PATH")"
  echo -e "$WARNINGS" | head -5
  echo "Add .catch() to .then() chains."
  echo "--------------------------------"
fi
exit 0
```

**Python/Go/Rust:** Skip this script — their async models handle errors differently (Python has try/except, Go returns errors, Rust has Result).

### `check-file-size.sh` (All languages)

```bash
#!/bin/bash
# File Size Warning — warns on 500+ line files (non-blocking)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in *.ts|*.tsx|*.js|*.jsx|*.py|*.go|*.rs) ;; *) exit 0 ;; esac
case "$FILE_PATH" in */__tests__/*|*/__mocks__/*|*.test.*|*.spec.*|*/.claude/*|*/scripts/*) exit 0 ;; esac
[ ! -f "$FILE_PATH" ] && exit 0

LINES=$(wc -l < "$FILE_PATH" | tr -d ' ')
if [ "$LINES" -gt 500 ]; then
  echo ""
  echo "--- File Size Warning ---"
  echo "$(basename "$FILE_PATH"): $LINES lines (limit: 500)"
  echo "Extract into smaller modules."
  echo "-------------------------"
fi
exit 0
```

`chmod +x` all scripts after writing.

## Step 6: Scaffold 9 Portable Skills

Write each skill to `.claude/commands/` as a standalone markdown file with YAML frontmatter. Write the FULL skill content — each must be self-contained.

### 1. `health.md` — Project Health Dashboard

**Model hint:** haiku. Run 6 checks in parallel and produce a report card.

**Checks:** (1) Type safety — run type checker, report error count. (2) Test suite — run tests, report pass/fail. (3) Dependency health — outdated + vulnerable deps. (4) TODO/FIXME/HACK scan — count by category across source dirs. (5) Large files — source files over 500 lines. (6) Source stats — file count + LOC by directory.

**Auto-detect commands** from project files: `package.json` → npm test, `pyproject.toml` → pytest, `go.mod` → go test, `Cargo.toml` → cargo test. Same for type checkers and dep audit tools.

**Report format:** Each check gets ✅/❌/⚠️. Overall grade: A+ (all green) through F (can't run checks).

### 2. `preflight.md` — Pre-Push Gate

**Model hint:** haiku. 5 sequential checks, blocks on type/test failures.

1. Type check (BLOCKING — stop on errors)
2. Test suite (BLOCKING — stop on failures)
3. Debug statements (WARNING — language-appropriate grep patterns)
4. Lint/style (WARNING — if linter config exists)
5. Large files (WARNING — over 500 lines)

**Verdict:** CLEAR TO PUSH ✅ or BLOCKED ❌ with details.

### 3. `code-review.md` — Multi-Agent Code Review

**Model hint:** sonnet. Routes by file count for efficiency.

1. Count changed files vs last commit or vs main
2. **1-3 files (Path A):** Single-pass review — correctness, security, performance, quality. Check: logic errors, null handling, input validation, injection vectors, hardcoded secrets, unused imports, naming, type safety, test coverage.
3. **4+ files (Path B):** Spawn 3 parallel Sonnet agents — (Agent 1) Architecture + Security, (Agent 2) Correctness + Performance, (Agent 3) Quality + DX.
4. Synthesize findings with severity ratings (critical/warning/info) and file:line references.
5. **Verdict:** APPROVED / NEEDS CHANGES / BLOCKED.

### 4. `deep-review.md` — 5-Agent Deep Review

**Model hint:** sonnet. For significant changes, new features, or pre-release audits.

1. Collect changed files (main...HEAD)
2. Spawn 5 parallel Sonnet agents:
   - **Architecture:** Dependencies, module boundaries, API surface, patterns, file organization
   - **Security:** Input validation, auth checks, secrets, injection, OWASP Top 10, data exposure
   - **Performance:** Re-computation, caching, N+1 queries, unbounded iterations, memory leaks, bundle impact
   - **Correctness:** Logic errors, null handling, error propagation, type safety, race conditions, state consistency
   - **DX:** Readability, naming, documentation, test coverage, error messages, pattern consistency
3. Synthesize, deduplicate, assign severity. Report with file:line references and verdict.

### 5. `ready-to-commit.md` — Smart Commit Prep

**Model hint:** sonnet. Categorizes changes, suggests message, chains review + preflight.

1. Detect changes: `git status --porcelain` + `git diff --cached --name-only`
2. Categorize: COMPONENT, SERVICE, TYPE, TEST, CONFIG, DOCS, STYLE, OTHER — based on file path patterns
3. Route by scope:
   - **Small (1-5 files, 1 category):** Suggest conventional commit message, ask to confirm
   - **Medium (6-15 files, 2-3 categories):** Run `/code-review` first, then suggest message
   - **Large (16+ files or 4+ categories):** Warn about splitting, suggest how. If user insists, run `/deep-review`
4. Run `/preflight` — if BLOCKED, stop
5. Stage specific files (never `git add -A`), commit with agreed message
6. Post-commit: show `git log --oneline -3`, offer to push, suggest `/retro`

### 6. `retro.md` — Post-Session Retrospective

**Model hint:** sonnet. 4-agent analysis of recent work.

1. Gather context: `git log --oneline -20`, `git diff --stat HEAD~10`, CLAUDE.md, skill inventory, auto-memory
2. Spawn 4 parallel agents:
   - **Lessons Learned:** Patterns that worked [KEEP], caused friction [STOP], new gotchas [GOTCHA], techniques [TECHNIQUE]
   - **Skills Auditor:** Skills used this session, stale paths, missing skills, description accuracy
   - **CLAUDE.md Freshness:** Versions current? Structure matches reality? Missing gotchas?
   - **Workflow Efficiency:** Permission gaps, automation opportunities, repeated manual steps
3. Synthesize into retro report with prioritized action items
4. Execute user-approved actions: update memory, CLAUDE.md, skills, settings

### 7. `future-feature.md` — Feature Backlog Manager

**Model hint:** sonnet. Extracts feature ideas from docs, deduplicates, prioritizes.

1. Scan sources: `docs/reviews/`, `docs/reports/`, `docs/notes/`, GitHub issues (if gh available), existing backlog
2. Extract features: title, description, source, category (UI/API/Perf/Security/DX/Infra/Content)
3. Deduplicate: exact + near-duplicate detection
4. Tier: T1 (Fix Existing), T2 (Enhance), T3 (New Feature), T4 (Implemented). Rank by impact × effort.
5. Write `docs/future-features/FEATURE_BACKLOG.md` with tables per tier
6. Optional: BUILD_PLAN.md grouping T1+T2 into sprints (3-5 features each)
7. Print summary: sources scanned, features extracted, dedupes merged, top new ideas

### 8. `learn.md` — Interactive Codebase Tutor

**Model hint:** opus. Socratic method with predict-then-reveal.

**3 mentor personalities:** The Professor (structured, fundamentals-first), The Practitioner (hands-on, example-driven), The Philosopher (Socratic, trade-off explorer). User picks at session start.

**Teaching method:** (1) Show actual project code, (2) ask learner to predict behavior/purpose, (3) reveal answer, (4) connect to broader patterns, (5) pose "what if" variation.

**Topic discovery:** Analyze project structure, recent git history, CLAUDE.md patterns. Suggest 5 topics ranked by relevance.

**Session flow:** Setup → 3-5 exploration rounds (difficulty scales with answers) → hands-on challenge → wrap-up with takeaways.

**Progress tracking:** `docs/courses/<topic>/progress.json` with sessions, concepts covered, accuracy, difficulty level.

**Quiz mode:** 5 questions from covered topics using actual project code.

### 9. `vibes.md` — Positive Mindset Priming

**No model hint (uses default).** Research-backed ~5 minute launch sequence.

This is the longest skill (~310 lines). Write the FULL content with all 10 steps:

1. **Streak tracking** — persistent JSON at `~/.claude/vibes/streak.json`, milestones at 7/14/30/60/100 days
2. **Breathing prompt** — 3 slow breaths (4-4-6 cadence), vagal tone activation
3. **Category selection** — randomly pick 2-3 from: Inspiration, Humor, Discovery, Reframe, Brain Teaser, Flow Fuel, Focus. Bias by mood if argument provided (stressed → Reframe+Humor, low energy → Inspiration+Flow Fuel)
4. **Web search** — fresh content per category, never canned quotes from training data
5. **Interactive presentation** — one category at a time via AskUserQuestion. Brain teasers: ask first, reveal after answer. Humor: riff off their energy
6. **What went well** — ask for 2 recent wins
7. **Growth questions** — 2-3 from pool spanning gratitude, energy, growth, mindset, impact
8. **Focus Lock-In** — 5 rotating frameworks tracked in streak.json: (A) MIT + If-Then, (B) WOOP Mental Contrasting, (C) Attention Anchor, (D) Distraction Defense, (E) Simple Intention. Each has science citation.
9. **Journal** — save to `~/.claude/vibes/journal/YYYY-MM-DD.md` with wins, content, growth answers, focus commitment
10. **Closing energy** — 2-3 sentences referencing specific session content, then stop

**Key rules:** Under 5 min total. Fresh web search only. Interactive not lecture. Rotate frameworks to prevent habituation. Never fabricate research.

## Step 7: Generate CLAUDE.md

Write `CLAUDE.md` with pre-filled universal sections and TODO markers. Replace all `$VARIABLES` with actual values from Step 2.

```markdown
# [Project Name] — CLAUDE.md

> Generated by `/big-gulps-huh`. Fill in the TODOs to make Claude useful for YOUR project.

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
- Don't add features or refactor beyond what was asked

## Verification Checklist
- [ ] `$LINT_CMD` passes with 0 errors
- [ ] `$TEST_CMD` passes
- [ ] No debug print statements in production code
- [ ] No type safety bypasses
- [ ] New files have tests

## Clarification Protocol
When a request is ambiguous, Claude MUST ask before implementing:
1. "Which approach do you prefer?" (with trade-offs)
2. "Should this be temporary or permanent?"
3. "What's the expected behavior for edge case X?"
Never guess on architecture decisions.

## Hook Reference
| Hook | Type | What |
|------|------|------|
| .env blocker | Blocking | Prevents editing .env files |
| Console sentinel | Warning | Warns on debug prints |
| Type assertion | Warning | Warns on type safety bypasses |
| Async safety | Warning | Warns on unguarded promises |
| File size | Warning | Warns on 500+ line files |
| Session greeting | Info | Shows branch + uncommitted count |

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Language | $LANG |
| Framework | <!-- TODO --> |
| Test Runner | $TEST_CMD |
| Linter | $LINT_CMD |
| Package Manager | $PKG_MGR |

## Commands
| Command | What |
|---------|------|
| `$TEST_CMD` | Run tests |
| `$LINT_CMD` | Type check / lint |
| <!-- TODO --> | <!-- TODO --> |

## File Structure
<!-- TODO: Map your actual project structure -->
\```
src/           # Source code
tests/         # Test files
scripts/       # Build & check scripts
docs/          # Documentation
.claude/       # Claude Code config & skills
\```

## Code Patterns
<!-- TODO: Document your patterns -->
- Components: TODO
- Services: TODO
- State management: TODO
- Error handling: TODO

## Common Gotchas
- `.env` files are protected — edit manually
- Commits over 200 lines trigger a warning
- Direct pushes to main are blocked — use PR workflow
<!-- TODO: Add project-specific gotchas -->

## Custom Skills
| Skill | What |
|-------|------|
| `/health` | Project health report |
| `/preflight` | Pre-push checks |
| `/code-review` | Multi-agent code review |
| `/deep-review` | 5-agent deep review |
| `/retro` | Post-session retrospective |
| `/future-feature` | Feature backlog management |
| `/ready-to-commit` | Smart commit prep |
| `/learn` | Codebase tutor |
| `/vibes` | Focus priming |
```

## Step 8: Generate Big Gulps Guide

Write `docs/BIG_GULPS_GUIDE.md` using the `$TONE` from Step 2. Use the corresponding template below EXACTLY — do not mix tones or improvise sections.

---

### Template: Sarcastic (default)

```markdown
# The Big Gulps Guide

> "Big gulps, huh? Welp, see ya later!" — Lloyd Christmas, professional optimist

*A sarcastic but genuinely helpful guide to not breaking things.*

---

## What Just Happened

You (or someone who cares about you) just ran `/big-gulps-huh` and scaffolded a complete Claude Code collaboration setup. That means git hooks, AI guardrails, portable skills, and a CLAUDE.md constitution. You now have more safety nets than a Cirque du Soleil performer.

---

## The Rules

### 1. Never Push to Main
The `pre-push` hook will block you. Main is sacred. You work on branches, you make PRs, you get them merged. Not negotiable.
**DYOR:** [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)

### 2. Conventional Commits or Go Home
Every commit needs a prefix: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, etc. "fixed stuff" is not a commit message, it's a cry for help.
**DYOR:** [Conventional Commits](https://www.conventionalcommits.org/)

### 3. Keep Commits Small
The `pre-commit` hook warns at 200+ lines. If your commit touches 47 files, that's not a commit, that's a hostage situation.
**DYOR:** [Atomic commits](https://www.pauline-vos.nl/atomic-commits/)

### 4. Don't Touch .env Through Claude
The blocker hook will physically prevent it. Credentials in AI chat history is how you end up on Hacker News for the wrong reasons.
**DYOR:** [12-Factor Config](https://12factor.net/config)

---

## The Skills (Your New Superpowers)

| Skill | What It Does | When to Use It |
|-------|-------------|----------------|
| `/health` | Types, tests, deps, TODOs, file sizes | "Is everything still working?" |
| `/preflight` | Pre-push verification suite | Before every push. Every. Single. One. |
| `/code-review` | Multi-agent code review | After finishing a feature, before PR |
| `/deep-review` | 5-agent parallel deep review | Important changes or new architecture |
| `/retro` | Post-session retrospective | End of a work session — captures lessons |
| `/future-feature` | Feature extraction & prioritization | After reviews, feedback, brainstorms |
| `/ready-to-commit` | Smart commit prep | When you're ready to commit (duh) |
| `/learn` | Interactive codebase tutor | When you're new or exploring |
| `/vibes` | Focus priming | Monday mornings. Trust us. |

**Pro tip:** `/preflight` before pushing + `/health` when things feel off. Everything else is bonus XP.

---

## The Hooks (Things That Yell at You)

| Hook | What It Checks | Why It Exists (Because Someone Did This) |
|------|---------------|------------------------------------------|
| pre-push | Pushes to main | Pushed untested code to main at 2am. Production went down. |
| pre-commit | Commit size > 200 lines | Made a 3,000-line commit called "updates". Nobody could review it. |
| commit-msg | Commit prefix | Wrote "asdf" as a commit message. Needed to find it 6 months later. |
| .env blocker | .env edits via Claude | AI assistant committed AWS keys to a public repo. |
| Console sentinel | Debug prints | Left `console.log("here")` in production. Users saw it. |
| Type assertion | `as any` usage | Cast everything to `any`. Created 47 runtime errors. |
| Async safety | Missing .catch() | Forgot error handling. App silently failed for 3 days. |
| File size | 500+ lines | Created a 2,400-line "utils.ts". It's still haunted. |
| Session greeting | Branch + status | Started coding on main. Didn't notice for 2 hours. |

---

## The CLAUDE.md (Your Project's Constitution)

The `CLAUDE.md` file has TODO markers. **Fill them in.** This isn't busywork — it's what makes Claude useful for YOUR project instead of giving generic answers.

Priority TODOs:
1. **Tech Stack** — so Claude knows your tools
2. **File Structure** — so Claude finds things without asking
3. **Code Patterns** — so Claude writes code like yours
4. **Common Gotchas** — so Claude skips your past mistakes

Think of it as onboarding docs for an AI that reads fast and knows nothing.

---

## Quick Start

1. **Read this guide** *(gold star)*
2. **Fill in CLAUDE.md TODOs** — Tech Stack, File Structure, Code Patterns minimum
3. **Run `bash scripts/setup-hooks.sh`** to verify hooks
4. **Try `/health`** for project status
5. **Make a test branch:** `git checkout -b test/my-first-branch`
6. **Test commit:** `git commit -m "test: verify hook setup"`
7. **Run `/preflight`** before pushing

All 7 work? Welcome to the guardrail life.

---

## FAQ

**Q: Can I push to main?** No.
**Q: But what if—** No.
**Q: Really small change, promise it's fine?** `git push --no-verify` for genuine emergencies. Use it for convenience and the hooks judge you silently.
**Q: Commit message error?** Prefix with: `feat:` `fix:` `docs:` `refactor:` `test:` `chore:` `style:` `perf:` `ci:` `build:` `revert:`
**Q: Console.log warnings broken?** Working perfectly. Remove your debug statements.
**Q: What's `/vibes`?** Productivity science disguised as fun. Try it Monday.
**Q: Worth all this setup?** You'll thank us when a hook catches something at 2am that would've been a production incident at 8am.

---

## One More Thing

This is a starting point, not a straitjacket:
- Add project-specific hooks as patterns emerge
- Create custom skills for repetitive workflows
- Update CLAUDE.md as your project evolves
- Run `/retro` regularly to capture what you've learned

Fewer "oh no" moments. More "oh nice" moments.

---

*Generated by `/big-gulps-huh`*
*DYOR: Do Your Own Research. Links above are starting points, not gospel.*
```

---

### Template: Professional

```markdown
# Development Environment Guide

*A practical guide to collaborative development with Claude Code.*

---

## Overview

This project is configured with automated development guardrails: git hooks for workflow enforcement, AI-assisted code quality hooks, portable development skills, and a project configuration file (CLAUDE.md).

---

## Development Workflow

**Branch Protection:** All changes go through pull requests. The `pre-push` hook prevents direct pushes to main.
*Ref: [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)*

**Commit Standards:** Commits require conventional prefixes (`feat:`, `fix:`, `docs:`, etc.) enforced by the `commit-msg` hook. Enables automated changelogs and searchable history.
*Ref: [Conventional Commits](https://www.conventionalcommits.org/)*

**Commit Size:** The `pre-commit` hook warns at 200+ lines. Smaller commits improve reviewability and enable granular reverts.
*Ref: [Atomic Commits](https://www.pauline-vos.nl/atomic-commits/)*

**Credential Safety:** The `.env` blocker hook prevents Claude from editing environment files, keeping credentials out of AI conversation logs.
*Ref: [12-Factor Config](https://12factor.net/config)*

---

## Available Skills

| Skill | Purpose | Recommended Usage |
|-------|---------|-------------------|
| `/health` | Project health report | Diagnosing issues |
| `/preflight` | Pre-push verification | Before every push |
| `/code-review` | Multi-agent code review | Before pull requests |
| `/deep-review` | 5-agent deep review | Significant changes |
| `/retro` | Session retrospective | End of work sessions |
| `/future-feature` | Feature backlog management | After feedback cycles |
| `/ready-to-commit` | Commit preparation | Before committing |
| `/learn` | Codebase tutor | Onboarding, exploration |
| `/vibes` | Focus priming | Session start |

**Recommended workflow:** `/preflight` before every push. `/health` for diagnostics.

---

## Automated Hooks

| Hook | Checks | Type | Rationale |
|------|--------|------|-----------|
| pre-push | Main branch pushes | Blocking | Enforces code review before production integration |
| pre-commit | Commit size | Warning | Reduces review burden and revert risk |
| commit-msg | Commit format | Blocking | Enables searchable history and automated changelogs |
| .env blocker | .env file edits | Blocking | Prevents credential exposure in AI logs |
| Console sentinel | Debug statements | Warning | Removes development artifacts from production |
| Type assertion | Type safety bypasses | Warning | Maintains type system integrity |
| Async safety | Unguarded promises | Warning | Prevents silent runtime failures |
| File size | 500+ line files | Warning | Promotes modular architecture |
| Session greeting | Branch + status | Info | Provides situational awareness on startup |

---

## CLAUDE.md Configuration

Complete the TODO sections in `CLAUDE.md` to optimize Claude's assistance:
1. **Tech Stack** — Technologies and versions
2. **File Structure** — Project directory layout
3. **Code Patterns** — Established conventions
4. **Common Gotchas** — Known pitfalls and constraints

---

## Getting Started

1. Complete CLAUDE.md TODO sections
2. Verify hooks: `bash scripts/setup-hooks.sh`
3. Run `/health` for project status
4. Create test branch: `git checkout -b test/setup-verification`
5. Verify commit hooks: `git commit -m "test: verify setup"`
6. Run `/preflight` before pushing

---

*Generated by `/big-gulps-huh`*
*Reference links are starting points — consult official documentation for current information.*
```

---

### Template: Minimal

```markdown
# Dev Environment

## Workflow
- Branch → PR → merge (no direct pushes to main)
- Conventional commits: `feat:` `fix:` `docs:` `refactor:` `test:` `chore:`
- 200+ line commits trigger warning
- .env files protected from AI edits

## Skills

| Skill | Purpose |
|-------|---------|
| `/health` | Project health report |
| `/preflight` | Pre-push checks |
| `/code-review` | Code review |
| `/deep-review` | Deep 5-agent review |
| `/retro` | Session retrospective |
| `/future-feature` | Feature backlog |
| `/ready-to-commit` | Commit preparation |
| `/learn` | Codebase tutor |
| `/vibes` | Focus priming |

## Hooks

| Hook | Checks | Blocking |
|------|--------|----------|
| pre-push | Main branch pushes | Yes |
| pre-commit | Commit size | No |
| commit-msg | Commit format | Yes |
| .env blocker | .env edits | Yes |
| Console sentinel | Debug statements | No |
| Type assertion | Type bypasses | No |
| Async safety | Missing .catch() | No |
| File size | 500+ lines | No |

## Setup
1. Fill in CLAUDE.md TODOs
2. `bash scripts/setup-hooks.sh`
3. `/health`
4. `git checkout -b test/setup && git commit -m "test: verify hooks"`
5. `/preflight`

## References
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [12-Factor Config](https://12factor.net/config)

---

*Generated by `/big-gulps-huh`*
```

## Step 9: Final Report

After scaffolding, print:

```
✅ Big Gulps scaffolding complete!

  Git Hooks:
    .git/hooks/pre-push       — PR-only workflow enforced
    .git/hooks/pre-commit     — 200-line commit warning
    .git/hooks/commit-msg     — Conventional commits required

  Claude Code Hooks:
    .claude/settings.local.json — [N] hooks wired

  Check Scripts:
    scripts/[list actual scripts written]

  Skills (9):
    .claude/commands/ — health, preflight, code-review, deep-review,
    retro, future-feature, ready-to-commit, learn, vibes

  Documentation:
    CLAUDE.md                    — Fill in the TODOs!
    docs/BIG_GULPS_GUIDE.md      — Share with your team

  Next steps:
    1. Fill in CLAUDE.md TODOs (Tech Stack, File Structure, Code Patterns)
    2. Run: bash scripts/setup-hooks.sh
    3. Try: /health
    4. Read: docs/BIG_GULPS_GUIDE.md
```

If `$TUTORIAL_MODE` was active, add: "Tutorial complete! You now understand all 5 layers."

---

## Tutorial Mode

When `$TUTORIAL_MODE=true`, insert teaching pauses between each layer. After writing each layer's files, output an explanation block and use AskUserQuestion with "Continue to next layer?" before proceeding. If user says "skip" or "just finish", complete remaining layers without pauses.

### After Layer 1 (Git Hooks):

```
📚 LAYER 1: Git Protection
===========================

3 git hooks now live in .git/hooks/:

PRE-PUSH — The Bouncer
  Blocks pushing directly to main. Every change goes through
  branch → PR → review → merge. Non-negotiable.

PRE-COMMIT — The Friendly Nudge
  Warns (doesn't block) at 200+ lines. Big commits are hard
  to review and hard to revert. "Is this really ONE change?"

COMMIT-MSG — The Grammar Police
  Requires prefixes like "feat:" or "fix:". Makes git log
  searchable and changelogs automatic.

Also created:
  .gitattributes     — binary file handling (images, fonts, locks)
  scripts/setup-hooks.sh — hook installer for teammates

💡 Git hooks run automatically before/after git operations.
   They live in .git/hooks/ and are NOT committed — each clone
   needs to run setup-hooks.sh to install them.
```

### After Layer 2 (Claude Code Hooks):

```
📚 LAYER 2: Claude Code Hooks
===============================

.claude/settings.local.json now has AI guardrails:

.ENV BLOCKER (Blocking — prevents the action)
  Claude cannot edit .env files. Protects credentials from
  appearing in AI logs or being accidentally committed.

CONSOLE SENTINEL (Warning — lets it through, shows message)
  Flags debug print statements in production code.

TYPE ASSERTION DETECTOR (Warning)
  Catches type safety bypasses (as any, # type: ignore).

ASYNC SAFETY (Warning)
  Finds .then() chains without .catch(). Unhandled rejections
  cause silent failures.

FILE SIZE (Warning)
  Flags files over 500 lines. Big files = hard to maintain.

SESSION GREETING (Info — just shows status)
  Shows current branch + uncommitted count on startup.

💡 "Blocking" hooks prevent the action (exit 2).
   "Warning" hooks let it through but show a message (exit 0).
```

### After Layer 3 (Check Scripts):

```
📚 LAYER 3: Check Scripts
===========================

Shell scripts in scripts/ power the Layer 2 hooks.

How they work:
  1. Claude edits a file
  2. Hook triggers, pipes edit info to the script
  3. Script reads file path from JSON stdin
  4. Checks if it's a source file (not test, not config)
  5. Greps for problems, prints warning if found

This pattern is reusable — copy any script and change the
grep pattern for your own checks (hardcoded URLs, deprecated
APIs, TODO comments, etc.).

💡 All scripts exit 0 (non-blocking warnings). To make one
   a hard stop, change to exit 1. The .env blocker uses
   exit 2 — that's the blocking signal.
```

### After Layer 4 (Skills):

```
📚 LAYER 4: Portable Skills
=============================

9 skills now live in .claude/commands/:

Most used:
  /health     — "Is my project broken?" in one command
  /preflight  — Run before every push (types + tests + lint)
  /vibes      — Productivity science. Seriously. Try it.

Power tools:
  /code-review  — Multiple AI agents review your code
  /deep-review  — 5 parallel agents for serious changes
  /retro        — Captures lessons after a work session

Planning:
  /future-feature  — Feature extraction from docs/reviews
  /ready-to-commit — Categorizes changes, suggests messages
  /learn           — Interactive tutor for YOUR codebase

💡 Skills are markdown files that tell Claude HOW to do
   something. Read them, edit them, create your own.
```

### After Layer 5 (CLAUDE.md + Guide):

```
📚 LAYER 5: Documentation
===========================

CLAUDE.md — Your project's constitution
  Every section you fill in makes Claude smarter about YOUR
  project. The TODOs aren't optional — they're the difference
  between generic help and project-aware help.

  Priority: Tech Stack → File Structure → Code Patterns → Gotchas

docs/BIG_GULPS_GUIDE.md — The onboarding guide
  Share with anyone joining the project. Explains everything
  in plain language with reference links.

💡 CLAUDE.md is read at the start of every Claude conversation.
   The more accurate it is, the less time correcting assumptions.

🎓 Tutorial complete! You understand all 5 layers.
   Next: Fill in the CLAUDE.md TODOs, then try /health.
```
