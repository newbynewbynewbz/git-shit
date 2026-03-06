---
name: future-feature
description: Extract, deduplicate, and prioritize feature ideas from reviews, reports, and notes
model-hint: sonnet
---

# Future Feature Extractor

Collects feature ideas from multiple sources, deduplicates, prioritizes, and maintains a living backlog.

## Step 1: Collect Sources

Scan for feature idea sources in the project:
- `docs/reviews/` — review reports, user feedback
- `docs/reports/` — audit reports, quality reports
- `docs/notes/` — brainstorm notes, meeting notes
- GitHub issues (if `gh` CLI available): `gh issue list --label "enhancement" --limit 50`
- `FEATURE_BACKLOG.md` (if exists — load existing backlog)

For each source found, create an extraction file in `docs/future-features/extractions/`:
- Format: `[source-type]_[identifier].md`
- Each extraction lists features found with: title, description, source, context

Ask user if there are additional sources to scan (URLs, documents, etc.).

## Step 2: Extract Features

For each source, use a Sonnet agent to extract feature ideas:
- Each feature gets: title, 1-2 sentence description, source reference
- Tag with category: UI, API, Performance, Security, DX, Infrastructure, Content
- Note any dependencies mentioned

## Step 3: Deduplicate

Compare all extracted features against each other AND against existing backlog:
- Exact duplicates: merge, keep the richer description
- Near-duplicates: flag for user decision (merge or keep separate)
- Related features: note the relationship

## Step 4: Prioritize (Tier System)

Assign each feature to a tier:

| Tier | Label | Criteria |
|------|-------|----------|
| T1 | Fix Existing | Bugs, broken flows, regressions |
| T2 | Enhance Existing | Improvements to working features |
| T3 | New Feature | Net-new functionality |
| T4 | Implemented | Already done (move out of backlog) |

Within each tier, rank by estimated impact (H/M/L) and effort (H/M/L).

## Step 5: Update Backlog

Write `docs/future-features/FEATURE_BACKLOG.md`:

```
# Feature Backlog
Updated: [date]
Total: N features (X T1, Y T2, Z T3)

## Tier 1: Fix Existing
| # | Feature | Impact | Effort | Source |
|---|---------|--------|--------|--------|
| 1 | ...     | H      | L      | ...    |

## Tier 2: Enhance Existing
[same table format]

## Tier 3: New Feature
[same table format]

## Recently Implemented (T4)
[completed features for reference]
```

## Step 6: Build Plan (Optional)

If user requests, generate `docs/future-features/BUILD_PLAN.md`:
- Group T1+T2 features into sprints (3-5 features per sprint)
- Order sprints by dependency chain and impact
- Estimate sprint scope (S/M/L)
- Note blockers and prerequisites

## Step 7: Report

Print summary:
```
Feature Extraction Complete
===========================
Sources scanned: N
Features extracted: N (X new, Y existing)
Duplicates merged: N
Backlog: X T1, Y T2, Z T3

New high-impact features:
  1. [feature] — [why it matters]
  2. [feature] — [why it matters]
  ...
```
