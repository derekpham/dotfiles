#!/usr/bin/env bash

# Remove an explicitly armed personal-repository worktree at session end. Any
# uncertainty leaves the worktree intact.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
hook_cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$hook_cwd" ] && [ -d "$hook_cwd" ] || exit 0

worktree=$(git -C "$hook_cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
expected_head=$(git -C "$worktree" rev-parse --verify --quiet refs/worktree/cleanup-armed 2>/dev/null) || exit 0
current_head=$(git -C "$worktree" rev-parse HEAD 2>/dev/null) || exit 0
[ -n "$expected_head" ] && [ "$expected_head" = "$current_head" ] || exit 0
worktree_status=$(git -C "$worktree" status --porcelain 2>/dev/null) || exit 0
[ -z "$worktree_status" ] || exit 0

primary=$(git -C "$worktree" worktree list --porcelain 2>/dev/null |
  awk '/^worktree / { sub(/^worktree /, ""); print; exit }')
[ -n "$primary" ] && [ -d "$primary" ] && [ "$primary" != "$worktree" ] || exit 0

cd "$primary" || exit 0
git worktree remove "$worktree" >/dev/null 2>&1 || exit 0
