#!/bin/bash
# One-command hook installer for new cloners
# Run: bash scripts/setup-hooks.sh

HOOK_DIR=".git/hooks"

if [ ! -d ".git" ]; then
  echo "❌ Not a git repository. Run from project root."
  exit 1
fi

for hook in pre-push pre-commit commit-msg; do
  if [ -f "$HOOK_DIR/$hook" ]; then
    echo "✅ $hook installed"
  else
    echo "❌ $hook missing — check your .git/hooks/ directory"
  fi
done

chmod +x "$HOOK_DIR"/pre-push "$HOOK_DIR"/pre-commit "$HOOK_DIR"/commit-msg 2>/dev/null
echo ""
echo "Done. All hooks are executable."
