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

## No `ctrl.Finish()` in Go gomock tests

Don't write `defer ctrl.Finish()` after `gomock.NewController(t)`. Since gomock v1.5.0, the controller registers its own cleanup via `t.Cleanup`, so the explicit `Finish` is redundant. Just write `ctrl := gomock.NewController(t)` and move on.

## Coding workflow (Roblox projects only)

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

For any new session where the user asks to write code:

1. Check out `master` or `main` (whichever the repo uses) and run `git pull` to update it.
2. Enter a new worktree via `EnterWorktree` based on the updated `master`/`main` before making changes.
3. Delegate the implementation to the `code-writer` agent.
4. Before pushing, run PR review agents (`pr-correctness` and `pr-architecture`) on the changes.
5. When opening a PR, always create it as a draft (`gh pr create --draft`). Do not ask for permission to draft — just draft it. The user will mark it ready for review themselves.

Skip the worktree step only if the user explicitly overrides for a given task. Do not trigger for research, questions, or read-only exploration.

## PR descriptions

Whenever drafting or opening a PR, the description **must** begin with a `## Why` section that explains the motivation for the change.

Before drafting the PR, you **must** ask the human why this change is necessary — do not infer it from the diff or commit messages. Wait for their answer, then write the `## Why` section in their words.

The PR title **must** be a brief summary of both the *why* and the *how* of the PR — not just one or the other. Like the `## Why` section, the title's motivation half should come from the human's answer, not inferred from the diff.

The standard `## Summary` and `## Test plan` sections are typically useless: they reiterate implementation details the reviewer can read from the diff. Keep them minimal or omit them unless they add information the diff doesn't already convey (e.g. a manual test that ran outside CI, a non-obvious behavior change). The `## Why` is the section that earns its space.
