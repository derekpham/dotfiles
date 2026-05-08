# User-level instructions

## Coding workflow (Roblox projects only)

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

For any new session where the user asks to write code:

1. Check out `master` or `main` (whichever the repo uses) and run `git pull` to update it.
2. Enter a new worktree via `EnterWorktree` based on the updated `master`/`main` before making changes.
3. Delegate the implementation to the `code-writer` agent.
4. Before pushing, run PR review agents (`pr-correctness` and `pr-architecture`) on the changes.

Skip the worktree step only if the user explicitly overrides for a given task. Do not trigger for research, questions, or read-only exploration.
