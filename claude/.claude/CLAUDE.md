# User-level instructions

## Coding workflow (Roblox projects only)

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

For any new session where the user asks to write code:

1. Enter a new worktree via `EnterWorktree` before making changes.
2. Delegate the implementation to the `code-writer` agent.
3. Before pushing, run PR review agents (`pr-correctness` and `pr-architecture`) on the changes.

Skip the worktree step only if the user explicitly overrides for a given task. Do not trigger for research, questions, or read-only exploration.
