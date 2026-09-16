#!/usr/bin/env bash

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
command_text=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null)

if printf '%s' "$command_text" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+push([[:space:]]|$)' &&
   printf '%s' "$command_text" | grep -Eq '(^|[[:space:]:/])(master|main)([[:space:];&|]|$)'; then
  jq -cn '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked: git push to master/main is not allowed. Push a feature branch and open a PR instead."
    }
  }'
fi
