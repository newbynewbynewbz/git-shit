#!/bin/bash
# Git Shit: Branching Strategy Advisor
# Interactive workflow selection based on your team's deployment model.
# Recommends a branching strategy and suggested .gitshitrc settings.
# Usage: bash scripts/git-shit-workflow.sh
#
# Branching strategy principle:
# "Your branching strategy should mirror your deployment architecture."

set -eo pipefail

# Require interactive terminal
if [ ! -t 0 ]; then
  echo "Error: git-shit-workflow.sh requires interactive input."
  echo "Run it directly in your terminal: bash scripts/git-shit-workflow.sh"
  exit 1
fi

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"

# --- Header ---
echo ""
echo -e "${BOLD}GIT SHIT — BRANCHING STRATEGY ADVISOR${RESET}"
echo -e "${DIM}Answer 3 questions to find the right workflow for your team.${RESET}"
echo ""

# --- Question 1: Deployment model ---
echo -e "${BOLD}1. How do you deploy?${RESET}"
echo ""
echo "  [1] Continuously (multiple times per day, CI/CD)"
echo "  [2] Scheduled releases (weekly, monthly, versioned)"
echo "  [3] Environment-gated (staging -> pre-prod -> production)"
echo ""
read -rp "  Your choice [1/2/3]: " DEPLOY_MODEL
echo ""

case "$DEPLOY_MODEL" in
  1) DEPLOY="continuous" ;;
  2) DEPLOY="scheduled" ;;
  3) DEPLOY="environment" ;;
  *)
    echo "  Invalid choice. Defaulting to continuous."
    DEPLOY="continuous"
    ;;
esac

# --- Question 2: Multiple versions ---
echo -e "${BOLD}2. Do you maintain multiple versions simultaneously?${RESET}"
echo -e "${DIM}   (e.g., v1.x and v2.x both receiving patches)${RESET}"
echo ""
echo "  [y] Yes"
echo "  [n] No"
echo ""
read -rp "  Your choice [y/n]: " MULTI_VERSION
echo ""

case "$MULTI_VERSION" in
  y|Y|yes|Yes) VERSIONS="multi" ;;
  *) VERSIONS="single" ;;
esac

# --- Question 3: Team size ---
echo -e "${BOLD}3. Team size?${RESET}"
echo ""
echo "  [1] Solo or small (1-5 developers)"
echo "  [2] Medium (5-20 developers)"
echo "  [3] Large (20+ developers)"
echo ""
read -rp "  Your choice [1/2/3]: " TEAM_SIZE
echo ""

case "$TEAM_SIZE" in
  1) SIZE="small" ;;
  2) SIZE="medium" ;;
  3) SIZE="large" ;;
  *)
    echo "  Invalid choice. Defaulting to small."
    SIZE="small"
    ;;
esac

# --- Decision Logic ---
WORKFLOW=""
if [ "$DEPLOY" = "scheduled" ] && [ "$VERSIONS" = "multi" ]; then
  WORKFLOW="gitflow"
elif [ "$DEPLOY" = "environment" ]; then
  WORKFLOW="gitlab-flow"
elif [ "$DEPLOY" = "continuous" ] && [ "$SIZE" = "small" ]; then
  WORKFLOW="trunk-based"
elif [ "$DEPLOY" = "continuous" ]; then
  WORKFLOW="github-flow"
elif [ "$DEPLOY" = "scheduled" ] && [ "$SIZE" = "large" ]; then
  WORKFLOW="gitflow"
else
  WORKFLOW="github-flow"
fi

# --- Output ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case "$WORKFLOW" in
  trunk-based)
    echo -e "  ${BOLD}RECOMMENDED: Trunk-Based Development${RESET}"
    echo ""
    echo "  Single shared branch. Short-lived feature branches (hours, not days)."
    echo "  Merge multiple times per day. Use feature flags for incomplete work."
    echo ""
    echo -e "  ${CYAN}Branch flow:${RESET}"
    echo "    main <-- feat/xyz (merged within hours)"
    echo ""
    echo -e "  ${CYAN}Suggested .gitshitrc settings:${RESET}"
    echo "    PROTECTED_BRANCHES=main"
    echo "    BRANCH_PATTERN=\"^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)/.+\""
    echo "    BRANCH_NAMING_MODE=warn"
    echo "    LARGE_COMMIT_THRESHOLD=100    # smaller commits encouraged"
    echo ""
    echo -e "  ${CYAN}Prerequisites:${RESET}"
    echo "    - Strong CI/CD pipeline (tests run on every push)"
    echo "    - Feature flags for work-in-progress"
    echo "    - Fast code review turnaround"
    echo ""
    echo -e "  ${YELLOW}Benefit:${RESET} Eliminates merge hell. Rapid feedback. Easier debugging"
    echo "  with smaller diffs."
    echo ""
    echo -e "  ${YELLOW}Risk:${RESET} Requires discipline and automation. Without CI, broken code"
    echo "  lands on main."
    ;;

  github-flow)
    echo -e "  ${BOLD}RECOMMENDED: GitHub Flow${RESET}"
    echo ""
    echo "  One long-lived branch (main). Short-lived feature branches."
    echo "  PRs for code review. Merge to main = deploy."
    echo ""
    echo -e "  ${CYAN}Branch flow:${RESET}"
    echo "    main <-- feat/xyz (via PR, squash-merge)"
    echo ""
    echo -e "  ${CYAN}Suggested .gitshitrc settings:${RESET}"
    echo "    PROTECTED_BRANCHES=main"
    echo "    BRANCH_PATTERN=\"^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)/.+\""
    echo "    BRANCH_NAMING_MODE=warn"
    echo "    COMMIT_MSG_MODE=warn"
    echo ""
    echo -e "  ${YELLOW}Benefit:${RESET} Simple. Low ceremony. Main is always deployable."
    echo ""
    echo -e "  ${YELLOW}Risk:${RESET} Can't manage multiple release versions simultaneously."
    echo "  Not ideal for scheduled release cycles."
    ;;

  gitflow)
    echo -e "  ${BOLD}RECOMMENDED: Gitflow${RESET}"
    echo ""
    echo "  Two long-lived branches: main (production) and develop (integration)."
    echo "  Feature, release, and hotfix branches follow strict naming."
    echo ""
    echo -e "  ${CYAN}Branch flow:${RESET}"
    echo "    main (production releases, tagged)"
    echo "      develop <-- feature/xyz"
    echo "      release/1.2 --> main (when ready)"
    echo "      hotfix/critical --> main + develop"
    echo ""
    echo -e "  ${CYAN}Suggested .gitshitrc settings:${RESET}"
    echo "    PROTECTED_BRANCHES=main|develop"
    echo "    BRANCH_PATTERN=\"^(feature|bugfix|hotfix|release|docs|chore)/.+\""
    echo "    BRANCH_NAMING_MODE=warn"
    echo "    COMMIT_MSG_MODE=strict"
    echo ""
    echo -e "  ${YELLOW}Benefit:${RESET} Clear separation of concerns. Supports multiple"
    echo "  versions and scheduled releases."
    echo ""
    echo -e "  ${YELLOW}Risk:${RESET} High ceremony. Long-lived branches can diverge."
    echo "  Overkill for small teams or continuous deployment."
    echo ""
    echo -e "  ${DIM}Note: Vincent Driessen (Gitflow creator) reflected in 2020 that"
    echo "  for web apps with continuous delivery, simpler workflows work better.${RESET}"
    ;;

  gitlab-flow)
    echo -e "  ${BOLD}RECOMMENDED: GitLab Flow${RESET}"
    echo ""
    echo "  Feature branches merge to main, then flow downstream through"
    echo "  environment branches: main -> staging -> production."
    echo ""
    echo -e "  ${CYAN}Branch flow:${RESET}"
    echo "    main <-- feat/xyz (via PR)"
    echo "    main --> staging --> production (downstream promotion)"
    echo ""
    echo -e "  ${CYAN}Suggested .gitshitrc settings:${RESET}"
    echo "    PROTECTED_BRANCHES=main|staging|production"
    echo "    BRANCH_PATTERN=\"^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)/.+\""
    echo "    BRANCH_NAMING_MODE=warn"
    echo "    COMMIT_MSG_MODE=warn"
    echo ""
    echo -e "  ${YELLOW}Benefit:${RESET} Middle ground between GitHub Flow and Gitflow."
    echo "  Environment branches match your deployment pipeline."
    echo ""
    echo -e "  ${YELLOW}Risk:${RESET} More branches to manage than GitHub Flow. Environment"
    echo "  branches can drift if not automated."
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  ${BOLD}THE BRANCHING PRINCIPLE${RESET}"
echo -e "  ${DIM}Your branching strategy should mirror your deployment architecture.${RESET}"
echo ""
echo "  Continuous Deployment    -->  Trunk-Based or GitHub Flow"
echo "  Scheduled Releases       -->  Gitflow"
echo "  Environment Pipelines    -->  GitLab Flow"
echo ""
echo -e "  ${DIM}This is a recommendation, not a rule. Adapt to your team's needs.${RESET}"
echo ""
