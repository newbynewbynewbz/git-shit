#!/bin/bash
# Hook: File Size Warning
# Warns when an edited file exceeds 500 lines (non-blocking)
# Triggered by PostToolUse on Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# Only check source files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.py|*.go|*.rs) ;;
  *) exit 0 ;;
esac

# Skip test/mock/config files
case "$FILE_PATH" in
  */__tests__/*|*/__mocks__/*) exit 0 ;;
  */*.test.*|*/*.spec.*) exit 0 ;;
  */jest.setup*|*/jest.config*) exit 0 ;;
  */.claude/*|*/scripts/*) exit 0 ;;
esac

[ ! -f "$FILE_PATH" ] && exit 0

LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
THRESHOLD=500

if [ "$LINE_COUNT" -gt "$THRESHOLD" ]; then
  echo ""
  echo "--- File Size Warning ---"
  echo "File: $(basename "$FILE_PATH")"
  echo "Lines: $LINE_COUNT (threshold: $THRESHOLD)"
  echo ""
  echo "Consider extracting logic into separate modules:"
  echo "  - Hooks: hooks/use<Feature>.ts"
  echo "  - Utils: utils/<feature>.ts"
  echo "  - Components: components/<SubComponent>.tsx"
  echo "-------------------------"
  echo ""
fi

exit 0
