#!/bin/bash
# setup-hooks.sh — DEPRECATED, use setup.sh
echo "⚠️  setup-hooks.sh has been renamed to setup.sh"
echo "  Please update your docs/scripts to use: bash scripts/setup.sh"
echo ""
exec "$(dirname "$0")/setup.sh" "$@"
