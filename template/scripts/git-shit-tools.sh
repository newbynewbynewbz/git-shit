#!/bin/bash
# Git Shit: Recommended tools
# Information only — does NOT install anything

echo ""
echo "⚙️  Git Shit — Recommended Tools"
echo ""

# Detect OS and package manager
if [[ "$OSTYPE" == "darwin"* ]]; then
  PKG_MGR="brew install"
  OS_NAME="macOS"
elif command -v apt-get &>/dev/null; then
  PKG_MGR="sudo apt install"
  OS_NAME="Linux (apt)"
elif command -v dnf &>/dev/null; then
  PKG_MGR="sudo dnf install"
  OS_NAME="Linux (dnf)"
elif command -v pacman &>/dev/null; then
  PKG_MGR="sudo pacman -S"
  OS_NAME="Linux (pacman)"
else
  PKG_MGR=""
  OS_NAME="Unknown"
fi

echo "  Detected: $OS_NAME"
echo ""

# Tool definitions: name, check command, package name (brew), description
declare -a TOOLS=(
  "lazygit|lazygit|lazygit|Terminal UI for git — staging, branching, rebasing in a TUI"
  "delta|delta|git-delta|Syntax-highlighted diffs in your terminal"
  "difft|difft|difftastic|Structural diffs that understand your programming language"
  "git-absorb|git-absorb|git-absorb|Auto-amend fixup commits into the right place"
)

for tool_entry in "${TOOLS[@]}"; do
  IFS='|' read -r cmd_name check_name pkg_name description <<< "$tool_entry"

  if command -v "$check_name" &>/dev/null; then
    STATUS="✅ installed"
  else
    STATUS="not installed"
  fi

  printf "  %-14s %s\n" "$cmd_name" "— $description"
  if [ "$STATUS" = "✅ installed" ]; then
    printf "  %-14s %s\n" "" "$STATUS"
  elif [ -n "$PKG_MGR" ]; then
    printf "  %-14s %s  →  %s %s\n" "" "$STATUS" "$PKG_MGR" "$pkg_name"
  else
    printf "  %-14s %s  →  see docs for install instructions\n" "" "$STATUS"
  fi
  echo ""
done

echo "  None of these are required — git-shit works without them."
echo "  But they make git significantly more pleasant to use."
echo ""
