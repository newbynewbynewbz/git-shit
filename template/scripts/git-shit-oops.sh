#!/bin/bash
# Git Shit: Oops Matrix — quick fixes for common git mistakes
# Usage: bash scripts/git-shit-oops.sh [topic]
# Topics: message, file, staged, branch, undo, broken, diff
# No arguments shows the full cheatsheet.

set -euo pipefail

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
YELLOW="\033[33m"
GREEN="\033[32m"
CYAN="\033[36m"

print_header() {
  echo ""
  echo -e "${BOLD}GIT SHIT — OOPS MATRIX${RESET}"
  echo "Quick fixes for common git mistakes"
  echo ""
}

print_separator() {
  echo "  ─────────────────────────────────────────────────────────────────"
}

show_message() {
  echo ""
  echo -e "  ${BOLD}Wrong commit message?${RESET}"
  echo ""
  echo -e "  ${GREEN}git commit --amend${RESET}"
  echo "    Opens your editor to fix the last commit message."
  echo "    The commit hash changes — only do this before pushing."
  echo ""
  echo -e "  ${DIM}Already pushed? The message stays. Plan ahead next time.${RESET}"
  echo ""
}

show_file() {
  echo ""
  echo -e "  ${BOLD}Forgot a file in the last commit?${RESET}"
  echo ""
  echo -e "  ${GREEN}git add <file>${RESET}"
  echo -e "  ${GREEN}git commit --amend --no-edit${RESET}"
  echo "    Adds the file to the previous commit without changing the message."
  echo "    The commit hash changes — only do this before pushing."
  echo ""
}

show_staged() {
  echo ""
  echo -e "  ${BOLD}Staged a file you didn't mean to?${RESET}"
  echo ""
  echo -e "  ${GREEN}git restore --staged <file>${RESET}"
  echo "    Removes the file from staging. Your edits are safe in the working directory."
  echo ""
  echo -e "  ${DIM}Unstage everything:${RESET}"
  echo -e "  ${GREEN}git restore --staged .${RESET}"
  echo ""
}

show_branch() {
  echo ""
  echo -e "  ${BOLD}Committed to the wrong branch?${RESET}"
  echo ""
  echo "  Step by step:"
  echo -e "  ${GREEN}1. git branch correct-branch${RESET}        # save the commit as a new branch"
  echo -e "  ${GREEN}2. git reset --soft HEAD~${RESET}           # undo commit on current branch"
  echo -e "  ${GREEN}3. git checkout correct-branch${RESET}      # switch — your commit is already there"
  echo ""
  echo -e "  ${DIM}Step 1 copies the commit to the new branch. Step 2 removes it from"
  echo -e "  the wrong branch. Your changes are safe the entire time.${RESET}"
  echo ""
}

show_undo() {
  echo ""
  echo -e "  ${BOLD}Undo the last commit?${RESET}"
  echo ""
  echo -e "  ${CYAN}Keep changes staged:${RESET}"
  echo -e "  ${GREEN}git reset --soft HEAD~${RESET}"
  echo ""
  echo -e "  ${CYAN}Keep changes unstaged:${RESET}"
  echo -e "  ${GREEN}git reset HEAD~${RESET}"
  echo ""
  echo -e "  ${CYAN}Discard changes completely:${RESET}"
  echo -e "  ${GREEN}git reset --hard HEAD~${RESET}"
  echo -e "  ${DIM}  Warning: this deletes your work permanently.${RESET}"
  echo ""
}

show_broken() {
  echo ""
  echo -e "  ${BOLD}Everything is broken?${RESET}"
  echo ""
  echo "  Git remembers every state change. Find a safe point and jump back:"
  echo ""
  echo -e "  ${GREEN}git reflog${RESET}"
  echo "    Shows every HEAD movement — commits, checkouts, rebases, resets."
  echo "    Find the hash of the last known good state."
  echo ""
  echo -e "  ${GREEN}git reset --hard <hash>${RESET}"
  echo "    Resets everything to that state."
  echo -e "  ${DIM}  Warning: this discards uncommitted work.${RESET}"
  echo ""
  echo -e "  ${CYAN}Example:${RESET}"
  echo "    $ git reflog"
  echo "    abc1234 HEAD@{0}: rebase: something went wrong"
  echo "    def5678 HEAD@{1}: checkout: moving from main to feature"
  echo "    ghi9012 HEAD@{2}: commit: last known good state"
  echo ""
  echo "    $ git reset --hard ghi9012"
  echo ""
}

show_diff() {
  echo ""
  echo -e "  ${BOLD}What changed? Where am I?${RESET}"
  echo ""
  echo -e "  ${GREEN}git diff${RESET}              Unstaged changes (working directory vs staging)"
  echo -e "  ${GREEN}git diff --cached${RESET}     Staged changes (staging vs last commit)"
  echo -e "  ${GREEN}git diff HEAD${RESET}         All changes (working directory vs last commit)"
  echo -e "  ${GREEN}git status${RESET}            Overview of what's staged, modified, untracked"
  echo -e "  ${GREEN}git log --oneline -5${RESET}  Last 5 commits"
  echo ""
}

show_full_table() {
  print_header
  echo -e "  ${BOLD}SITUATION                             FIX${RESET}"
  print_separator
  echo "  Wrong commit message                git commit --amend"
  echo "  Forgot a file in last commit        git add <file> && git commit --amend --no-edit"
  echo "  Staged a file I didn't want         git restore --staged <file>"
  echo "  Committed to wrong branch           git branch <right> && git reset --soft HEAD~"
  echo "  Undo last commit (keep changes)     git reset --soft HEAD~"
  echo "  Everything is broken                git reflog -> git reset --hard <hash>"
  echo "  What changed?                       git diff (unstaged) / git diff --cached (staged)"
  print_separator
  echo ""
  echo -e "  ${DIM}For details on any topic:${RESET}"
  echo "    bash scripts/git-shit-oops.sh message"
  echo "    bash scripts/git-shit-oops.sh file"
  echo "    bash scripts/git-shit-oops.sh staged"
  echo "    bash scripts/git-shit-oops.sh branch"
  echo "    bash scripts/git-shit-oops.sh undo"
  echo "    bash scripts/git-shit-oops.sh broken"
  echo "    bash scripts/git-shit-oops.sh diff"
  echo ""
}

# --- Main ---
TOPIC="${1:-}"

case "$TOPIC" in
  message|msg)   show_message ;;
  file|forgot)   show_file ;;
  staged|unstage) show_staged ;;
  branch|wrong)  show_branch ;;
  undo|reset)    show_undo ;;
  broken|reflog) show_broken ;;
  diff|status)   show_diff ;;
  "")            show_full_table ;;
  *)
    echo ""
    echo "  Unknown topic: $TOPIC"
    echo ""
    echo "  Available topics: message, file, staged, branch, undo, broken, diff"
    echo ""
    exit 1
    ;;
esac
