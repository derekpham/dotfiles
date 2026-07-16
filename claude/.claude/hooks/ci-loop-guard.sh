#!/usr/bin/env bash
# Stop hook: keep the agent in the CI-monitoring loop until CI is green — but ONLY
# after the loop has been explicitly started with the /ship command. It does nothing
# during plain chat, test-review, implementation, or review cycles.
#
# The /ship skill arms the loop by writing the current epoch seconds to a
# "ci-loop-active" marker in the (worktree's) git dir. This hook blocks the agent
# from ending its turn while that marker is live AND the branch's open PR has
# pending/failing checks. The marker clears automatically when CI is green, the PR
# closes, or the marker is stale (older than the TTL below — a safety net for a
# shipped loop that was abandoned).
#
# Always fail OPEN (allow the stop) on any uncertainty — never trap the agent.
#
# Markers (in "$(git rev-parse --absolute-git-dir)"):
#   ci-loop-active    armed by /ship; contains epoch seconds. Presence => enforce.
#   ci-loop-escalate  one-shot: stuck; release once and stand down the loop.
set -uo pipefail

# Stale-marker safety net: an armed loop older than this (with no refresh) is treated
# as abandoned and cleared. /ship refreshes the marker on every push, so a live loop
# never expires; this only catches loops left behind by a crashed/abandoned session.
TTL_SECONDS=21600  # 6h

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
hook_cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$hook_cwd" ] && [ -d "$hook_cwd" ]; then
  cd "$hook_cwd" || exit 0
fi

git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null)
[ -n "$git_dir" ] || exit 0

# One-shot escalation: stuck and needs the user. Release once, and stand down the loop.
if [ -f "$git_dir/ci-loop-escalate" ]; then
  rm -f "$git_dir/ci-loop-escalate" "$git_dir/ci-loop-active"
  exit 0
fi

# Not armed -> no active loop (nobody ran /ship) -> never block.
[ -f "$git_dir/ci-loop-active" ] || exit 0

# Stale marker (armed long ago, never refreshed) -> treat as abandoned; clean + allow.
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

# Normalize each rollup entry to a single outcome, then count pending vs failing.
# CheckRun entries carry .status (+ .conclusion when COMPLETED); StatusContext
# entries carry .state. Handle both shapes.
counts=$(printf '%s' "$pr_json" | jq -r '
  [ .statusCheckRollup[]? |
    if has("status") and (.status != "COMPLETED") then "PENDING"
    elif has("status") then (.conclusion // "PENDING")
    else (.state // "PENDING") end
  ] as $o
  | ([ $o[] | select(. == "PENDING" or . == "EXPECTED" or . == "QUEUED" or . == "IN_PROGRESS" or . == "WAITING" or . == "REQUESTED") ] | length) as $p
  | ([ $o[] | select(. == "FAILURE" or . == "ERROR" or . == "CANCELLED" or . == "TIMED_OUT" or . == "ACTION_REQUIRED" or . == "STARTUP_FAILURE") ] | length) as $f
  | "\($p) \($f)"')
pending=${counts% *}
failed=${counts#* }

if [ "${pending:-0}" -gt 0 ] || [ "${failed:-0}" -gt 0 ]; then
  pr_number=$(printf '%s' "$pr_json" | jq -r '.number')
  reason="You ran /ship, so a CI-monitoring loop is active for PR #${pr_number}, and it is not green: ${pending:-0} check(s) still running, ${failed:-0} failing. Resume the loop now: poll gh pr checks, and fix any failure via the code-writer agent with a full self-review (pr-correctness + pr-architecture) before pushing. Do NOT stop until BOTH unit and integration tests pass with grep evidence. If passing is impossible without drastic or architectural changes, run: touch \"${git_dir}/ci-loop-escalate\" and then stop to explain the blocker to the user. If the user has asked you to stop monitoring, run: rm -f \"${git_dir}/ci-loop-active\" and then stop."
  jq -cn --arg r "$reason" '{decision: "block", reason: $r}'
  exit 0
fi

# All green -> loop complete. Stand down and allow the stop.
rm -f "$git_dir/ci-loop-active"
exit 0
