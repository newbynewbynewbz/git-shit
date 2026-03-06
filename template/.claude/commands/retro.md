---
name: retro
description: Post-session retrospective — captures lessons, audits skills, checks CLAUDE.md freshness
model-hint: sonnet
---

# Retro — Post-Session Retrospective

Run after a work session to capture lessons and keep project documentation fresh.

**Scope:** Last $ARGUMENTS commits (auto-detected or explicit)

## Step 0: Auto-Detect Scope

Determine how many commits to retro. Waterfall — first match wins:

| Priority | Source | Command | Condition |
|----------|--------|---------|-----------|
| 1 | **Explicit arg** | (parse $ARGUMENTS for a number) | User passed a number → use it |
| 2 | **Retro log** | Read `docs/retro/RETRO_LOG.md`, extract last entry's HEAD SHA | File exists + has entries → `git rev-list <sha>..HEAD --count` |
| 3 | **Today's commits** | `git log --oneline --since="midnight" \| wc -l` | Count > 0 → use it |
| 4 | **Fallback** | — | Use 10 |

**Clamp** result to range 1–50. Save as N.

Also save the current HEAD SHA:
```bash
git rev-parse HEAD
```
Save as HEAD_SHA (used in Step 5 for the retro log entry).

## Step 1: Gather Context

Read:
- Recent commits: `git log --oneline -N`
- Changed files: `git diff --stat HEAD~N`
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

Output: Skills health report with action items. For any proposed new skill, tag it as PROPOSED_SKILL with name, description, and evidence.

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

Output: Efficiency recommendations. For any repeated manual workflow that could become a skill, tag it as PROPOSED_SKILL with name, description, and evidence.

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

## Step 3.5: Trend Analysis

Read `docs/retro/RETRO_LOG.md`. If the file doesn't exist or has fewer than 2 entries:
> "Trend analysis available after 2+ retros. Skipping."

Otherwise, parse the last 5–10 entries (each starts with `## YYYY-MM-DD`). Identify:

| Trend Type | Trigger |
|------------|---------|
| **RECURRING GOTCHA** | Same gotcha keyword in 2+ entries |
| **PERSISTENTLY STALE** | Same skill flagged stale in 2+ entries |
| **CLAUDE.md DRIFT** | Same section flagged stale in 2+ entries |
| **DEFERRED TIP** | Same tip deferred in 2+ entries |

Append a `### Trends` section to the Step 3 report. If no trends: "No recurring patterns detected."

## Step 4: Execute Approved Actions

Present the action items to the user. For each approved item:
- Update auto-memory files with new lessons/gotchas
- Update CLAUDE.md sections that are stale
- Fix skill files that reference wrong paths
- Add new permission rules to settings.local.json

Only make changes the user explicitly approves.

If Agent 2 or Agent 4 flagged PROPOSED_SKILL entries that appeared in 2+ retros (from trends) or were flagged by both agents, note them as skill generation candidates. Present to user — never auto-create.

## Step 5: Append Retro Log

### Create retro log directory

If `docs/retro/` doesn't exist, create it.

### Append to retro log

Append to `docs/retro/RETRO_LOG.md` (create if missing, with header `# Retro Log\n\n`):

```markdown
## YYYY-MM-DD | N commits | <first_sha>..<HEAD_SHA>
- **Lessons:** X (breakdown by category)
- **Stale skills:** X (list names)
- **CLAUDE.md fixes:** X
- **Efficiency tips:** X (Y applied, Z deferred)
- **GOTCHAs:** comma-separated list of gotcha keywords
```

Values come from the Step 3 synthesized report. The SHA range uses `git log --oneline -N | tail -1 | cut -d' ' -f1` for the first SHA and HEAD_SHA from Step 0.
