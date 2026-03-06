---
name: health
description: Full project health check — types, tests, deps, TODOs, file sizes
model-hint: haiku
---

# Project Health Check

Run all 6 checks in parallel where possible, then produce a summary report card.

## Checks

### 1. Type Safety
Run the project's type checker (look for tsconfig.json → `npx tsc --noEmit`, pyproject.toml → `pyright`, go.mod → `go vet ./...`, Cargo.toml → `cargo check`). Report error count.

### 2. Test Suite
Run the project's test command (look for package.json scripts.test → run it, pytest.ini/pyproject.toml → `pytest`, go.mod → `go test ./...`, Cargo.toml → `cargo test`). Report pass/fail count.

### 3. Dependency Health
Check for outdated and vulnerable dependencies:
- Node: `npm outdated` + `npm audit`
- Python: `pip list --outdated` + `pip-audit` (if available)
- Go: `go list -m -u all`
- Rust: `cargo outdated` (if available) + `cargo audit` (if available)

### 4. TODO/FIXME Scan
Search all source files for TODO, FIXME, HACK, XXX comments. Count by category. List top 5 most urgent (FIXME > HACK > TODO).

### 5. Large File Detection
Find source files over 500 lines. List them sorted by size descending.

### 6. Source Stats
Count files by type across src/, lib/, app/, components/, services/, hooks/, utils/. Report total lines of code.

## Report Format

```
📊 Project Health Report
========================

Type Safety:    ✅ 0 errors  |  ❌ N errors
Test Suite:     ✅ N passing  |  ❌ N failing
Dependencies:   ✅ up to date |  ⚠️ N outdated, N vulnerable
TODOs:          N total (X FIXME, Y HACK, Z TODO)
Large Files:    N files over 500 lines
Source:         N files, ~N lines of code

Overall: [A+ / A / B / C / D / F based on checks]
```

Grading: A+ = all green, A = 1 warning, B = 2-3 warnings, C = type or test failures, D = both failing, F = can't even run checks.
