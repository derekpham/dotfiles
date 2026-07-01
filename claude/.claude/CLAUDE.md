# User-level instructions

## Coding workflow (Roblox projects only) — DO THIS FIRST

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

**DO NOT edit, write, or create any file before completing steps 1–2. DO NOT skip the worktree — editing files on master is never acceptable unless the user explicitly says so.**

For any new session where the user asks to write code:

### Phase 0: Setup

1. Check out `master` or `main` (whichever the repo uses) and run `git pull` to update it.
2. Enter a new worktree via `EnterWorktree` based on the updated `master`/`main` before making changes.

### Phase 1: Integration tests first (gate before coding)

3. **Determine if integration tests apply:**
   - If the project already has integration tests for the feature area being modified → **write integration tests first** (mandatory).
   - If this is a **new feature** with no existing integration tests → **ask the user** whether they want integration tests written first.
   - If modifying an existing workflow with no existing integration tests → **skip this phase** (assume no integration tests unless the user explicitly says otherwise).

4. **Write integration tests** (when applicable):
   - Test at public boundaries only: API endpoints, CLI output, exported package interfaces, database state, HTTP responses.
   - **Never** assert on internal function calls, struct layouts, dependency wiring, or implementation details.
   - Tests **must not break** on code refactors or architecture refactors (unless the requested change is itself architectural).
   - Delegate to the `code-writer` agent with these constraints explicitly stated in the prompt.

5. **Draft a PR with only the integration tests.** Use the `pr-create` skill. Ask for the Jira ticket first (or `ADHOC`).

6. **STOP — wait for user approval.** The user must manually review the integration tests and give explicit go-ahead before proceeding to Phase 2.

### Phase 2: Implementation + unit tests

7. Delegate the implementation to the `code-writer` agent with these rules in its prompt:
   - Achieve full branch coverage of all new/changed code paths. Skip generated code.
   - Write unit tests that **assert on behavior**, not implementation details.
   - Tests must survive dependency refactoring — if swapping an internal dependency forces unit test changes, the test is too tightly coupled.
   - Integration tests from Phase 1 must continue to pass without modification (unless they made a wrong assumption about test setup or behavior).

8. Before pushing, run the `pr-correctness` and `pr-architecture` subagents on the changes as a self-review. Both agents must also verify:
   - Unit tests assert on behavior, not implementation.
   - Integration tests were not modified (unless a wrong assumption was identified).
   - Branch coverage of new code paths looks complete.

9. Before creating the PR, ask the user for a Jira ticket number (e.g. `PROJ-123`). If there is no ticket, use `ADHOC`. Include the ticket in the PR title as a prefix (e.g. `PROJ-123: Add retry logic`).

10. When opening the PR, invoke the `pr-create` skill — it asks the human for the *why*, drafts a `## Why`-first body, and creates the PR as a draft.

### Phase 3: CI monitoring loop (mandatory after push)

11. **Identify which GitHub Actions run the tests.** Read the repo's `.github/workflows/` files to find which workflow(s) execute unit tests and integration tests.

12. **Start a monitoring loop** (poll every 3 minutes, 2-hour timeout that **resets on each new push**):
    - Check the PR's CI status via `gh`.
    - Once CI completes, **verify tests actually ran:**
      - For integration tests: grep CI logs for **specific test function names** (e.g. `PASS: TestFeatureX_Integration`) and show them to the user.
      - For unit tests: grep CI logs showing the **test file was executed** and show to the user.
    - If tests **pass** → show evidence and exit the loop.
    - If tests **fail:**
      - If failure is due to an **intermittent/flaky issue** (infra timeout, rate limit, unrelated test) → rerun the failed workflow via `gh run rerun --failed`.
      - If **unit tests** fail → fix the code/unit tests and push again. Reset the 2-hour timeout. Re-enter the loop.
      - If **integration tests** fail → you may **only** fix the integration test if it made a wrong assumption (test setup, incorrect behavioral expectation). Otherwise fix the implementation code. Push and reset the 2-hour timeout. Re-enter the loop.
    - If the loop times out (2 hours since last push with no new push) → alert the user and stop.

13. **Exit condition:** Both integration tests and unit tests pass, with grep evidence shown to the user.

Skip the worktree step only if the user explicitly overrides for a given task. Do not trigger for research, questions, or read-only exploration.

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

## Reviewing PRs on GitHub

When the user asks you to review a PR on GitHub (theirs or someone else's), invoke the `pr-review` skill. It runs the diff-review subagents, checks the PR's `## Why`, prefixes every candidate comment with `from Derek's PR Review Agent: `, and runs a confirm-before-post gate.
