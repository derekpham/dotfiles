#!/usr/bin/env bash
# Stop hook: keep the agent inside the Phase 3 CI-monitoring loop until CI is green.
#
# Blocks the agent from ending its turn when the current branch has an OPEN PR
# with any pending or failing check. Allows the stop when:
#   - there is no PR for the current branch, or the PR is not OPEN
#   - all checks have passed (nothing pending, nothing failing)
#   - jq or gh is unavailable (never trap the agent)
#   - an escalation marker exists (agent decided passing needs drastic changes)
#
# Worktree-safe: the Phase 0 workflow does all work inside a git worktree, whose
# branch/PR differ from the main checkout. A Stop hook may be launched from the
# main repo root, so we cannot trust the ambient cwd. Stop hooks receive a JSON
# payload on stdin that includes the working directory the agent was operating
# in (.cwd); we cd into that before touching git/gh so the guard evaluates the
# worktree's branch, not master.
#
# Escalation escape hatch: when passing is impossible without drastic/architectural
# change, the agent creates "<git-dir>/ci-loop-escalate" and then stops to ask the
# user. This hook consumes (removes) the marker and allows that single stop.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
hook_cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$hook_cwd" ] && [ -d "$hook_cwd" ]; then
  cd "$hook_cwd" || exit 0
fi

# --absolute-git-dir resolves to the worktree's own git dir (e.g.
# .../.git/worktrees/<name>), so the escalation marker is scoped per worktree.
git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null)
if [ -n "$git_dir" ] && [ -f "$git_dir/ci-loop-escalate" ]; then
  rm -f "$git_dir/ci-loop-escalate"
  exit 0
fi

command -v gh >/dev/null 2>&1 || exit 0

pr_json=$(gh pr view --json state,number,statusCheckRollup 2>/dev/null) || exit 0
[ -z "$pr_json" ] && exit 0

state=$(printf '%s' "$pr_json" | jq -r '.state // ""')
[ "$state" != "OPEN" ] && exit 0

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
  reason="CI is not green for PR #${pr_number}: ${pending:-0} check(s) still running, ${failed:-0} failing. Resume the Phase 3 CI-monitoring loop from CLAUDE.md now: read .github/workflows/, poll gh pr checks, and fix any failure via the code-writer agent with a full self-review (pr-correctness + pr-architecture) before pushing. Do NOT stop until BOTH unit and integration tests pass with grep evidence. If passing is impossible without drastic or architectural changes, run: touch \"${git_dir}/ci-loop-escalate\" and then stop to explain the blocker to the user."
  jq -cn --arg r "$reason" '{decision: "block", reason: $r}'
  exit 0
fi

exit 0
