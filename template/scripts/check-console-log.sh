#!/bin/bash
# Hook: Console Statement Sentinel
# Warns on console.log/warn/error in production code (non-blocking)
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

MATCHES=$(grep -nE "console\.(log|warn|error|info|debug|trace)\(" "$FILE_PATH" 2>/dev/null | grep -v "//.*console\." | head -5)

if [ -n "$MATCHES" ]; then
  echo ""
  echo "--- Warning: Console Statements ---"
  echo "File: $(basename "$FILE_PATH")"
  echo ""
  echo "$MATCHES"
  echo ""
  echo "Remove debug statements before committing. Use a logger instead."
  echo "------------------------------------"
  echo ""
fi

exit 0
