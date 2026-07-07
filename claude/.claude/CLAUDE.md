# User-level instructions

## Coding workflow (Roblox projects only) — DO THIS FIRST

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

**DO NOT edit, write, or create any file before completing steps 1–2. DO NOT skip the worktree — editing files on master is never acceptable unless the user explicitly says so.**

**DO NOT write code directly.** All code and test changes — including small iterative fixes — must be delegated to the `code-writer` agent. The main loop must never use Write/Edit on source files. The code-writer agent has its own rules for test coverage and conventions — do not override them. Describe the goal and provide context (relevant files, patterns, constraints), but do NOT enumerate implementation steps or specify test file names.

For any new session where the user asks to write code:

### Phase 0: Setup

1. Check out `master` or `main` (whichever the repo uses) and run `git pull` to update it.
2. Enter a new worktree via `EnterWorktree` based on the updated `master`/`main` before making changes.

### Phase 1: Plan (mandatory — always do this before writing any code)

3. **Plan the work.** Even if the user says "implement X," plan first. The plan must address:
   - What is being changed and why.
   - Which files/packages are affected.
   - **Integration tests:** Do existing integration tests cover this feature area? If yes, state whether new integration tests are needed and why/why not. If this is a new feature with no existing integration test coverage, ask the user whether they want integration tests. Resolve this during planning — never as an afterthought.
   - Present the plan to the user for approval before proceeding.

4. **If integration tests are needed**, write them first:
   - Test at public boundaries only: API endpoints, CLI output, exported package interfaces, database state, HTTP responses.
   - **Never** assert on internal function calls, struct layouts, dependency wiring, or implementation details.
   - Tests **must not break** on code refactors or architecture refactors (unless the requested change is itself architectural).
   - Delegate to the `code-writer` agent.
   - Draft a PR with only the integration tests. Use the `pr-create` skill. Ask for the Jira ticket first (or `ADHOC`).
   - **STOP — wait for user approval** before proceeding to implementation.

### Phase 2: Implementation + unit tests

5. Delegate the implementation to the `code-writer` agent. The code-writer will follow its own rules for:
   - Writing unit tests for all new/changed exported methods.
   - Full branch coverage of new code paths (unless awkward to achieve — e.g. platform-specific error paths, unreachable defensive branches).
   - Behavior-based assertions, not implementation-detail assertions.
   - Integration tests from Phase 1 must continue to pass without modification (unless they made a wrong assumption).

6. **Self-review before pushing.** Run `pr-correctness` and `pr-architecture` subagents on the diff. Both must verify:
   - All new exported methods have unit tests.
   - Coverage of new code paths is complete (flag gaps explicitly).
   - Unit tests assert on behavior, not implementation.
   - Integration tests were not modified (unless a wrong assumption was identified).

7. Before creating the PR, ask the user for a Jira ticket number (e.g. `PROJ-123`). If there is no ticket, use `ADHOC`. Include the ticket in the PR title as a prefix.

8. When opening the PR, invoke the `pr-create` skill — it asks the human for the *why*, drafts a `## Why`-first body, and creates the PR as a draft.

### Phase 3: CI monitoring loop (mandatory after every push)

9. **Read `.github/workflows/`** to understand which workflows run unit tests and integration tests. CI is a DAG — not all jobs are queued right away. Some workflows:
   - Depend on other workflows completing first (e.g. `workflow_run`, `needs:`).
   - Only run on specific path filters.
   - Are gated behind labels or manual triggers.
   You must read the repo's workflow files to know which job names to wait for and what triggers them. Don't assume all checks appear instantly or that an empty checks list means "nothing to run."

10. **Start a monitoring loop** (poll every 3 minutes, 2-hour timeout that **resets on each new push**):
    - Check the PR's CI status via `gh`.
    - Once CI completes, **verify tests actually ran:**
      - For unit tests: grep CI logs showing test files were executed.
      - For integration tests: grep CI logs for specific test function names (e.g. `PASS: TestFeatureX`).
    - If tests **pass** → show evidence to the user and exit the loop.
    - If tests **fail:**
      - If failure is **flaky** (infra timeout, rate limit, unrelated test) → rerun via `gh run rerun --failed`.
      - If **unit tests** fail → delegate fix to code-writer → self-review → push → restart loop.
      - If **integration tests** fail → fix only if the test made a wrong assumption; otherwise fix the implementation → self-review → push → restart loop.
    - If the loop times out (2 hours since last push) → alert the user and stop.

11. **Exit condition:** Both unit tests and integration tests pass, with grep evidence shown to the user.

### Rules that apply across all phases

- Skip the worktree step only if the user explicitly overrides.
- Do not trigger this workflow for research, questions, or read-only exploration.
- Every fix iteration (Phase 3 failures) goes through self-review before pushing — no "quick fix and push" shortcuts.

## No over-defensive constructor checks

Skip precondition checks that either (a) duplicate a clear error the caller would get anyway from downstream code, or (b) silently coerce invalid input to a "sensible default." These invariants belong in unit tests, not runtime code.

Examples of checks to **not** add at runtime:

- `if fileName == "" { return err }` when `os.Open` / `os.ReadFile` / etc. will fail with a clear error on the next line.
- `if interval <= 0 { interval = defaultInterval }` — silent coercion conflates "caller forgot to set it" with "caller explicitly passed 0" and papers over both.
- Nil checks on arguments that the caller is *expected* to pass — let the nil deref happen loudly rather than swapping in a silent fallback.

**Enforce via unit tests instead.** Config validation and precondition assertions belong in test time, not runtime. Write unit tests that verify constructors/configs reject invalid values — this catches misuse during development without adding runtime overhead or silent fallbacks in production.

How to decide: "If I remove this check, what does the caller see?" If the error is already clear (downstream `os` call fails, `time.NewTicker(0)` panics, etc.), the check is redundant — drop it. If you still want to guard against it, write a test that passes invalid input and asserts the expected failure.

If `0` / `""` / `nil` is meant as "use the default," use `*T`, an options struct, or a constructor that doesn't require it — so "not specified" is distinguishable from "explicitly invalid."

Exception: trust boundaries (user input, network APIs, parsing untrusted data). Validation there is legitimate.

## No `ctrl.Finish()` in Go gomock tests

Don't write `defer ctrl.Finish()` after `gomock.NewController(t)`. Since gomock v1.5.0, the controller registers its own cleanup via `t.Cleanup`, so the explicit `Finish` is redundant. Just write `ctrl := gomock.NewController(t)` and move on.

## Reviewing PRs on GitHub

When the user asks you to review a PR on GitHub (theirs or someone else's), invoke the `pr-review` skill. It runs the diff-review subagents, checks the PR's `## Why`, prefixes every candidate comment with `from Derek's PR Review Agent: `, and runs a confirm-before-post gate.
