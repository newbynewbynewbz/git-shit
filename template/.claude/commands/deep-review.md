---
name: deep-review
description: 5-agent parallel deep review for important changes or new architecture
model-hint: sonnet
---

# Deep Review — Multi-Agent Code Analysis

Use this for significant changes: new features, architectural shifts, or pre-release audits.

## Step 1: Identify Scope

Collect all changed files:
```bash
git diff --name-only main...HEAD
```

Read each file to understand the full change set.

## Step 2: Spawn 5 Parallel Agents

Launch 5 Sonnet agents simultaneously, each with a focused mandate:

### Agent 1: Architecture
- Dependency direction (no circular imports)
- Module boundaries and separation of concerns
- API surface area — is the public interface minimal?
- Consistent patterns across similar modules
- File organization and naming conventions

### Agent 2: Security
- Input validation at all system boundaries
- Authentication/authorization checks present where needed
- No hardcoded secrets, tokens, or credentials
- SQL/command injection prevention
- Data exposure in logs, errors, or API responses
- OWASP Top 10 relevant checks

### Agent 3: Performance
- Unnecessary computation or re-computation
- Missing caching opportunities
- N+1 query patterns
- Unbounded iterations over large data sets
- Memory leaks (unclosed resources, event listeners, subscriptions)
- Bundle size impact (unnecessary imports)

### Agent 4: Correctness
- Logic errors and edge cases
- Null/undefined handling
- Error propagation and recovery
- Type safety (no `any` escapes, proper generics)
- Race conditions in async code
- Consistent state management

### Agent 5: Developer Experience
- Code readability and naming clarity
- Documentation for non-obvious logic
- Test coverage for new and changed code
- Error messages that help debugging
- Consistent patterns with existing codebase

## Step 3: Synthesize

Collect all 5 agent reports. Deduplicate findings. Assign severity:
- **Critical:** Security vulnerabilities, data loss risk, broken functionality
- **Warning:** Performance issues, missing tests, architectural concerns
- **Info:** Style suggestions, minor improvements, documentation gaps

## Report Format

```
Deep Review: [branch name]
===========================
Agents: Architecture | Security | Performance | Correctness | DX
Files analyzed: N

CRITICAL (must fix):
  [findings with file:line]

WARNING (should fix):
  [findings with file:line]

INFO (nice to have):
  [findings with file:line]

Verdict: APPROVED ✅ | NEEDS CHANGES ⚠️ | BLOCKED ❌
```
