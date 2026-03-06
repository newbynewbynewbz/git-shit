#!/bin/bash
# Hook: `as any` Sentinel
# Warns on `as any` type assertions in production code (non-blocking)
# Triggered by PostToolUse on Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# Only check .ts/.tsx files
case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Skip test/mock/config files
case "$FILE_PATH" in
  */__tests__/*|*/__mocks__/*) exit 0 ;;
  */*.test.ts|*/*.test.tsx) exit 0 ;;
  */*.spec.ts|*/*.spec.tsx) exit 0 ;;
  */jest.setup*) exit 0 ;;
  */.claude/*|*/scripts/*) exit 0 ;;
esac

AS_ANY_MATCHES=$(grep -nE '\bas any\b' "$FILE_PATH" 2>/dev/null | grep -v "//.*as any" | head -5)

if [ -n "$AS_ANY_MATCHES" ]; then
  echo ""
  echo "--- Warning: \`as any\` Type Assertion ---"
  echo "File: $(basename "$FILE_PATH")"
  echo ""
  echo "$AS_ANY_MATCHES"
  echo ""
  echo "\`as any\` bypasses TypeScript safety. Use proper types or \`unknown\` with type guards."
  echo "------------------------------------------"
  echo ""
fi

exit 0
