---
name: retro
description: Post-session retrospective — captures lessons, audits skills, checks CLAUDE.md freshness
model-hint: sonnet
---

# Retro — Post-Session Retrospective

Run after a work session to capture lessons and keep project documentation fresh.

## Step 1: Gather Context

Read:
- Recent commits: `git log --oneline -20`
- Changed files: `git diff --stat HEAD~10`
- CLAUDE.md (if it exists)
- `.claude/commands/` skill inventory
- Auto-memory files (if they exist)

## Step 2: Spawn 4 Parallel Agents

### Agent 1: Lessons Learned
Analyze recent commits and diffs for:
- Patterns that worked well (keep doing)
- Patterns that caused friction (stop doing)
- New gotchas discovered (document them)
- Techniques worth remembering

Output: Bullet list of lessons, each tagged [KEEP], [STOP], [GOTCHA], or [TECHNIQUE].

### Agent 2: Skills Auditor
Review `.claude/commands/` skills against recent session activity:
- Were any skills used? Which ones?
- Are any skills outdated or referencing stale paths?
- Are there repetitive workflows that could become new skills?
- Do skill descriptions match their actual behavior?

Output: Skills health report with action items.

### Agent 3: CLAUDE.md Freshness
Compare CLAUDE.md against current project state:
- Are tech stack versions current?
- Do file structure descriptions match reality?
- Are code patterns documented that are actually used?
- Are there gotchas that should be added?
- Do verification commands still work?

Output: List of CLAUDE.md sections needing updates, with suggested changes.

### Agent 4: Workflow Efficiency
Analyze the session for process improvements:
- Were there permission prompts that should be added to allow list?
- Were there repeated manual steps that hooks could automate?
- Were there context switches that better task organization could prevent?
- How many turns did tasks take vs expected?

Output: Efficiency recommendations.

## Step 3: Synthesize

Combine all 4 agent reports into a single retro document:

```
Session Retro — [date]
======================

Lessons Learned:
  [KEEP] ...
  [STOP] ...
  [GOTCHA] ...

Skills Health:
  [status of each skill]

CLAUDE.md Freshness:
  [sections needing updates]

Workflow:
  [efficiency recommendations]

Action Items:
  1. [specific action]
  2. [specific action]
  ...
```

## Step 4: Execute Approved Actions

Present the action items to the user. For each approved item:
- Update auto-memory files with new lessons/gotchas
- Update CLAUDE.md sections that are stale
- Fix skill files that reference wrong paths
- Add new permission rules to settings.local.json

Only make changes the user explicitly approves.
