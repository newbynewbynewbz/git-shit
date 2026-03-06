---
name: preflight
description: Pre-push verification — types, tests, lint, debug statements, large files
model-hint: haiku
---

# Preflight Checks

Run these 5 checks sequentially. Stop on first blocking failure.

## Check 1: Type Safety (BLOCKING)
Run the project's type checker. If errors > 0, report them and STOP. Do not proceed.

## Check 2: Test Suite (BLOCKING)
Run the project's test command. If any tests fail, report them and STOP.

## Check 3: Debug Statements (WARNING)
Search source files (not tests, not scripts, not .claude/) for debug print statements:
- TypeScript/JavaScript: `console.(log|warn|error|info|debug|trace)(`
- Python: `print(` and `breakpoint()`
- Go: `fmt.Print`
- Rust: `println!` and `dbg!`

Report matches but don't block.

## Check 4: Lint / Style (WARNING)
If a linter config exists (eslint, ruff, golangci-lint, clippy), run it. Report issues but don't block.

## Check 5: Large Files (WARNING)
List any source files over 500 lines.

## Summary

```
Preflight Results
=================
✅/❌ Types:     [result]
✅/❌ Tests:     [result]
⚠️/✅ Debug:     [N statements found / clean]
⚠️/✅ Lint:      [N issues / clean]
⚠️/✅ Size:      [N large files / all under 500]

Verdict: CLEAR TO PUSH ✅  |  BLOCKED ❌
```
