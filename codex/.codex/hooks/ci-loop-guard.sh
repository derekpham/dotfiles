#!/usr/bin/env bash

# Continue an explicitly armed CI loop until the PR is green. Fail open on any
# uncertainty so an abandoned marker cannot trap the agent.
set -uo pipefail

TTL_SECONDS=21600

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
hook_cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$hook_cwd" ] && [ -d "$hook_cwd" ]; then
  cd "$hook_cwd" || exit 0
fi

git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || exit 0

if [ -f "$git_dir/ci-loop-escalate" ]; then
  rm -f "$git_dir/ci-loop-escalate" "$git_dir/ci-loop-active"
  exit 0
fi

[ -f "$git_dir/ci-loop-active" ] || exit 0

armed_at=$(cat "$git_dir/ci-loop-active" 2>/dev/null || true)
if printf '%s' "$armed_at" | grep -Eq '^[0-9]+$'; then
  now=$(date +%s)
  if [ $((now - armed_at)) -gt "$TTL_SECONDS" ]; then
    rm -f "$git_dir/ci-loop-active"
    exit 0
  fi
fi

command -v gh >/dev/null 2>&1 || exit 0

pr_json=$(gh pr view --json state,number,statusCheckRollup 2>/dev/null) || exit 0
if [ -z "$pr_json" ]; then
  rm -f "$git_dir/ci-loop-active"
  exit 0
fi

state=$(printf '%s' "$pr_json" | jq -r '.state // ""')
if [ "$state" != "OPEN" ]; then
  rm -f "$git_dir/ci-loop-active"
  exit 0
fi

counts=$(printf '%s' "$pr_json" | jq -r '
  [ .statusCheckRollup[]? |
    if has("status") and (.status != "COMPLETED") then "PENDING"
    elif has("status") then (.conclusion // "PENDING")
    else (.state // "PENDING") end
  ] as $outcomes
  | ([ $outcomes[] | select(. == "PENDING" or . == "EXPECTED" or . == "QUEUED" or . == "IN_PROGRESS" or . == "WAITING" or . == "REQUESTED") ] | length) as $pending
  | ([ $outcomes[] | select(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED" or . == "STARTUP_FAILURE") ] | length) as $failed
  | "\($pending) \($failed)"')
pending=${counts% *}
failed=${counts#* }

if [ "${pending:-0}" -gt 0 ] || [ "${failed:-0}" -gt 0 ]; then
  pr_number=$(printf '%s' "$pr_json" | jq -r '.number')
  reason="The ship skill armed CI monitoring for PR #${pr_number}, which is not green: ${pending:-0} check(s) pending and ${failed:-0} failing. Resume monitoring now. Fix real failures through a writer agent, run pr_correctness and pr_architecture before pushing, then re-arm the loop. If success requires a drastic or architectural change, create ci-loop-escalate and explain the blocker."
  jq -cn --arg reason "$reason" '{decision: "block", reason: $reason}'
  exit 0
fi

rm -f "$git_dir/ci-loop-active"
