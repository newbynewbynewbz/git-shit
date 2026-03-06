#!/bin/bash
# Hook: Async Promise Safety
# Warns on fire-and-forget async calls missing .catch() (non-blocking)
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

# Check for .then() chains without .catch() within a 30-line window
THEN_WITHOUT_CATCH=$(grep -nE '\.then\(' "$FILE_PATH" 2>/dev/null | while read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  END_LINE=$((LINE_NUM + 30))
  HAS_CATCH=$(sed -n "${LINE_NUM},${END_LINE}p" "$FILE_PATH" 2>/dev/null | grep -c '\.catch(')
  if [ "$HAS_CATCH" -eq 0 ]; then
    echo "$line"
  fi
done | head -5)

if [ -n "$THEN_WITHOUT_CATCH" ]; then
  echo ""
  echo "--- Warning: Unguarded Async Calls ---"
  echo "File: $(basename "$FILE_PATH")"
  echo ""
  echo "$THEN_WITHOUT_CATCH"
  echo ""
  echo "Fire-and-forget promises without .catch() can crash or hang the app."
  echo "Add .catch(err => logger.error('context:', err)) to each call."
  echo "--------------------------------------"
  echo ""
fi

exit 0
