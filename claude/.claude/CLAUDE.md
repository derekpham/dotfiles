# User-level instructions

## No over-defensive constructor checks

Skip precondition checks that either (a) duplicate a clear error the caller would get anyway from downstream code, or (b) silently coerce invalid input to a "sensible default."

Examples of checks to **not** add:

- `if fileName == "" { return err }` when `os.Open` / `os.ReadFile` / etc. will fail with a clear error on the next line.
- `if interval <= 0 { interval = defaultInterval }` — silent coercion conflates "caller forgot to set it" with "caller explicitly passed 0" and papers over both.
- Nil checks on arguments that the caller is *expected* to pass — let the nil deref happen loudly rather than swapping in a silent fallback.

How to decide: "If I remove this check, what does the caller see?" If the error is already clear (downstream `os` call fails, `time.NewTicker(0)` panics, etc.), the check is redundant — drop it.

If `0` / `""` / `nil` is meant as "use the default," use `*T`, an options struct, or a constructor that doesn't require it — so "not specified" is distinguishable from "explicitly invalid."

Exception: trust boundaries (user input, network APIs, parsing untrusted data). Validation there is legitimate.

## Coding workflow (Roblox projects only)

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

For any new session where the user asks to write code:

1. Check out `master` or `main` (whichever the repo uses) and run `git pull` to update it.
2. Enter a new worktree via `EnterWorktree` based on the updated `master`/`main` before making changes.
3. Delegate the implementation to the `code-writer` agent.
4. Before pushing, run PR review agents (`pr-correctness` and `pr-architecture`) on the changes.

Skip the worktree step only if the user explicitly overrides for a given task. Do not trigger for research, questions, or read-only exploration.
