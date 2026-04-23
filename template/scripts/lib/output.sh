#!/bin/bash
# Git Shit: output helpers
# Quiet-on-success is the house rule. Hooks emit zero bytes when everything
# is fine, and only print when they have something actionable to say.
#
# All helpers read TEACH_MODE from the environment (set by profile.sh or
# the host hook). No globals are mutated here.

# Print args to stdout only when TEACH_MODE=on. Use for optional explanations.
gs_teach() {
  [ "${TEACH_MODE:-off}" = "on" ] && printf '%s\n' "$@"
}

# Print args to stderr. Use for errors and hard-block reasons.
gs_err() {
  printf '%s\n' "$@" >&2
}

# Print args then exit 1. Use for hard blocks.
gs_fail() {
  gs_err "$@"
  exit 1
}
