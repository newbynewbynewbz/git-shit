#!/bin/bash
# Git Shit: profile resolver
# Sourced by every hook. Expands GIT_SHIT_PROFILE into per-knob defaults.
#
# Resolution order (highest wins):
#   1. Environment variable:   GIT_SHIT_<KEY>
#   2. Explicit .gitshitrc:    <KEY>=...
#   3. Profile default:        set here based on GIT_SHIT_PROFILE
#   4. Ultimate fallback:      hard-coded default in each hook
#
# This file only sets the PROFILE layer. It never overwrites a variable
# the caller already set, which keeps v1 configs working unchanged.

_gs_set_default() {
  # Set $1 to $2 only if $1 is empty/unset. Never clobbers explicit config.
  local name="$1" value="$2"
  if [ -z "${!name:-}" ]; then
    eval "$name=\"\$value\""
  fi
}

_gs_apply_profile() {
  local profile="${GIT_SHIT_PROFILE:-${PROFILE:-solo}}"

  case "$profile" in
    solo)
      _gs_set_default TEACH_MODE off
      _gs_set_default COMMIT_MSG_MODE off
      _gs_set_default BRANCH_NAMING_MODE off
      _gs_set_default LARGE_COMMIT_THRESHOLD 500
      _gs_set_default SECRET_SCAN on
      _gs_set_default PROTECTED_BRANCHES main
      ;;
    team)
      _gs_set_default TEACH_MODE on
      _gs_set_default COMMIT_MSG_MODE warn
      _gs_set_default BRANCH_NAMING_MODE warn
      _gs_set_default LARGE_COMMIT_THRESHOLD 200
      _gs_set_default SECRET_SCAN on
      _gs_set_default PROTECTED_BRANCHES main
      ;;
    strict)
      _gs_set_default TEACH_MODE on
      _gs_set_default COMMIT_MSG_MODE strict
      _gs_set_default BRANCH_NAMING_MODE strict
      _gs_set_default LARGE_COMMIT_THRESHOLD 100
      _gs_set_default SECRET_SCAN on
      _gs_set_default PROTECTED_BRANCHES "main|develop"
      ;;
    *)
      # Unknown profile: fall back to solo defaults, emit hint to stderr
      echo "git-shit: unknown profile '$profile' — falling back to 'solo'" >&2
      _gs_set_default TEACH_MODE off
      _gs_set_default COMMIT_MSG_MODE off
      _gs_set_default BRANCH_NAMING_MODE off
      _gs_set_default LARGE_COMMIT_THRESHOLD 500
      _gs_set_default SECRET_SCAN on
      _gs_set_default PROTECTED_BRANCHES main
      ;;
  esac

  _gs_set_default BRANCH_PATTERN "^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert|research)/.+"
}

# Called by hooks after sourcing .gitshitrc. Idempotent — safe to source twice.
_gs_apply_profile
