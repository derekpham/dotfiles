#!/usr/bin/env bash

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
command_text=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null)

if printf '%s' "$command_text" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'; then
  jq -cn '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: "PR created. CI monitoring remains off until the user invokes the ship skill. Stop for review unless the user requested more work."
    }
  }'
fi
