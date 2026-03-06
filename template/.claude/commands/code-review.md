---
name: code-review
description: Multi-agent code review — routes by file count for efficiency
model-hint: sonnet
---

# Code Review (Smart Router)

## Step 1: Detect Scope

Count files changed since last commit (or since branch diverged from main):
```bash
git diff --name-only HEAD~1  # or git diff --name-only main...HEAD
```

## Step 2: Route by File Count

### Path A: Small Review (1-3 files)
Review directly in a single pass. Check each file for:

**Correctness:**
- Logic errors, off-by-one, null/undefined handling
- Missing error handling at system boundaries
- Race conditions in async code

**Security:**
- User input validation
- SQL/command injection vectors
- Hardcoded secrets or credentials
- Unsafe deserialization

**Performance:**
- Unnecessary re-renders or recomputation
- Missing memoization for expensive operations
- N+1 query patterns
- Unbounded list/array operations

**Quality:**
- Unused imports and dead code
- Naming clarity (functions = verbs, booleans = is/has/should)
- Type safety (no `any`, no `as unknown as X` chains)
- Test coverage for new logic

### Path B: Large Review (4+ files)
Spawn 3 parallel Sonnet agents, each reviewing a subset of files:

**Agent 1 — Architecture & Security:**
- Cross-file dependency direction (no circular imports)
- Consistent error handling patterns
- Security checklist (input validation, auth checks, data exposure)

**Agent 2 — Correctness & Performance:**
- Logic correctness across all changed files
- Performance patterns (memoization, query efficiency, re-render prevention)
- Edge cases and error paths

**Agent 3 — Quality & DX:**
- Code style consistency
- Naming conventions
- Type safety
- Test coverage gaps

## Step 3: Synthesize

Combine all findings into a review report:

```
Code Review: [branch name]
===========================
Files reviewed: N
Severity breakdown: X critical, Y warning, Z info

[Findings grouped by severity, each with file:line reference]

Verdict: APPROVED ✅ | NEEDS CHANGES ⚠️ | BLOCKED ❌
```
