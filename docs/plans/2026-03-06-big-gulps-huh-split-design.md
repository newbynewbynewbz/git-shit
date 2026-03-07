# Big Gulps Huh — Repo Split & Redesign

> Design approved 2026-03-06. Splitting git-shit and big-gulps-huh into two independent repos, redesigning big-gulps-huh as an onboarding-first Claude Code scaffolder.

## Problem

git-shit and big-gulps-huh are two different products serving two different audiences, currently stuffed into one repo. git-shit is a standalone git enhancement toolkit for any developer. big-gulps-huh is a full Claude Code collaboration scaffolder for friends, family, and new devs joining projects or starting their own.

Mixing them creates confusion: someone who just wants git hooks has to wade through 9 Claude Code skills, 4 check scripts, and an onboarding guide they don't need.

## Decision: Full Split, Approach B (Course Pack Model)

Two independent repos. big-gulps-huh inlines git hook logic (no cross-repo dependency). /learn ships with preloaded course packs as standalone markdown files.

## Repo 1: git-shit (cleanup)

### Remove
- `.claude/commands/big-gulps-huh.md`
- `template/.claude/commands/` (all 9 skills)
- `template/scripts/check-console-log.sh`, `check-as-any.sh`, `check-async-safety.sh`, `check-file-size.sh`
- `template/CLAUDE.md`
- `template/docs/BIG_GULPS_GUIDE.md`

### Keep
- `.claude/commands/git-shit.md`
- `template/git-hooks/*` (3 hooks)
- `template/scripts/setup-hooks.sh`
- `template/.gitattributes`
- `template/.github/pull_request_template.md`
- `LICENSE`

### Modify
- `README.md` — rewrite as git-only, add link to big-gulps-huh at bottom

## Repo 2: big-gulps-huh (new — newbynewbynewbz/big-gulps-huh)

### Structure

```
big-gulps-huh/
  .claude/commands/
    big-gulps-huh.md              <- scaffolder skill (inlines git hooks)
  template/
    scripts/
      setup-hooks.sh
      check-console-log.sh
      check-as-any.sh
      check-async-safety.sh
      check-file-size.sh
    .claude/commands/
      health.md
      preflight.md
      code-review.md
      deep-review.md
      retro.md
      future-feature.md
      ready-to-commit.md
      learn.md                    <- enhanced with course pack engine
      vibes.md
    docs/
      BIG_GULPS_GUIDE.md
      courses/
        claude-code-basics/
          course.md
        terminal-basics/
          course.md
        git-fundamentals/
          course.md
    .gitattributes
    .github/
      pull_request_template.md
    CLAUDE.md                     <- skeleton with TODOs
  README.md
  LICENSE
```

### Onboarding Flow (big-gulps-huh.md redesign)

#### Phase 1: Experience Detection

Single question: "Have you used Claude Code before?"

| Answer | $EXPERIENCE | Behavior |
|--------|-------------|----------|
| "Nope, first time" | new | Auto-detect stack, full teaching, dial-back check at layer 3 |
| "A little" | some | Auto-detect stack, light teaching, dial-back check at layer 2 |
| "Yeah, I'm good" | experienced | Ask stack questions directly, status-only output |

#### Phase 2: Auto-Detect Stack

Scan project files (package.json, pyproject.toml, go.mod, Cargo.toml) to determine language, test runner, linter, package manager. Teaching calibrated to $EXPERIENCE:

- **new**: explain what was found in plain language
- **some**: confirm findings with brief context
- **experienced**: list findings, offer override

If no project markers found (fresh project), ask language in plain terms.

#### Phase 3: Scaffold with Contextual Teaching

Teaching woven into setup — short, practical explanations after each file/hook is created. Not walls of text.

Dial-back check fires once (layer 3 for new, layer 2 for some):
"Want me to keep explaining things, or just finish setting up?"

If user says "just finish", remaining layers get status-only output.

#### Phase 4: Landing

Hands-on "try this now" moment:
1. Create a branch
2. Make a change
3. Commit with conventional prefix
4. See hooks in action

Then nudge /learn calibrated to experience level:
- new: "Type /learn — start with Claude Code Basics"
- some: "Try /learn when you're exploring"
- experienced: "/health for project status"

### Enhanced /learn Skill

#### Architecture
Engine (learn.md) + course packs (docs/courses/<name>/course.md). Engine discovers courses automatically by scanning the courses directory.

#### Arguments
```
/learn                  -> menu: built-in courses + project topics
/learn <topic>          -> start/continue session
/learn quiz             -> quiz on covered material
/learn progress         -> show progress across all courses
/learn contribute       -> guide for creating new course packs
```

#### Preloaded Courses (in order)
1. **Claude Code Basics** — skills, CLAUDE.md, hooks, prompting, workflow
2. **Terminal Basics** — pwd, ls, cd, mkdir, grep, find, pipes
3. **Git Fundamentals** — branches, commits, PRs, hooks, recovery

#### Course Pack Format
```markdown
---
name: Course Name
description: One-line description
difficulty: beginner|intermediate|advanced
estimated_sessions: 3-5
prerequisites: []
---

# Course Name

## Module 1: Topic
### Concept: What Is X?
[Teaching content with predict-then-reveal prompts]

### Exercise: Try X
[Hands-on task using the actual project]
```

#### Adaptive Behavior
| Project State | /learn Shows |
|---|---|
| Fresh (0-5 source files) | Built-in courses only |
| Growing (5-20 files) | Built-in courses + "Recent changes" topic |
| Mature (20+ files) | Built-in courses + 3-5 discovered project topics |
| Has custom courses in docs/courses/ | All of the above + custom courses |

#### /learn contribute
Shows template for creating a course pack. Auto-suggests topics based on complex areas of codebase, areas with low test coverage, recently refactored code.

#### Preserved from original
- Mentor personalities (Professor/Practitioner/Philosopher)
- Predict-then-reveal teaching method
- Progress tracking (progress.json per course/topic)
- Quiz mode with actual project code
- Difficulty scaling based on answers

### Session Greeting Evolution

SessionStart hook rotates tips based on user progress:

```
Sessions 1-3:   "Tip: Type /learn to start with Claude Code Basics"
Sessions 4-6:   "Tip: /learn progress — see what you've covered"
Sessions 7+:    "Tip: /learn quiz — test what you've learned"
All courses done: "Tip: /health for project status"
Idle/stuck:     "Tip: Feeling stuck? Type /learn to build momentum"
```

### Unchanged Skills
health, preflight, code-review, deep-review, retro, future-feature, ready-to-commit, vibes — ship as-is from current template.

## Implementation Order

1. Write design doc (this file)
2. Create big-gulps-huh repo on GitHub
3. Write the 3 preloaded course packs
4. Rewrite learn.md with course pack engine
5. Rewrite big-gulps-huh.md with new onboarding flow + inlined git hooks
6. Copy unchanged skills to new repo template
7. Write new README for big-gulps-huh
8. Clean up git-shit repo (remove big-gulps-huh content)
9. Rewrite git-shit README
10. Push both repos
