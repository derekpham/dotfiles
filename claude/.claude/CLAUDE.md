# User-level instructions

## Coding workflow (Roblox projects only) — DO THIS FIRST

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos.

**DO NOT edit, write, or create any file before completing steps 1–2. DO NOT skip the worktree — editing files on master is never acceptable unless the user explicitly says so.**

**DO NOT write code directly.** All code and test changes — including small iterative fixes — must be delegated to the `code-writer` agent (or `code-writer-hard` for genuinely hard tasks: subtle concurrency, tricky algorithms, large multi-file changes). The main loop must never use Write/Edit on source files. The code-writer agents have their own rules for test coverage and conventions — do not override them. Describe the goal and provide context (relevant files, patterns, constraints), but do NOT enumerate implementation steps or specify test file names.

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

5. Delegate the implementation to the `code-writer` agent (or `code-writer-hard` for genuinely hard tasks). The code-writer will follow its own rules for:
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

> **Enforced by a Stop hook.** `~/.claude/hooks/ci-loop-guard.sh` runs whenever you try to end your turn. If the current branch has an OPEN PR with any pending or failing check, the hook **blocks you from stopping** and tells you to resume this loop. You cannot quietly exit while CI is red — the only sanctioned exits are the exit condition (all green, step 12) or the escalation path (step 11).

9. **Read `.github/workflows/`** to understand which workflows run unit tests and integration tests. CI is a DAG — not all jobs are queued right away. Some workflows:
   - Depend on other workflows completing first (e.g. `workflow_run`, `needs:`).
   - Only run on specific path filters.
   - Are gated behind labels or manual triggers.
   You must read the repo's workflow files to know which job names to wait for and what triggers them. Don't assume all checks appear instantly or that an empty checks list means "nothing to run."

10. **Start a monitoring loop** (poll every 3 minutes; the 2-hour budget **resets on each new push**):
    - Check the PR's CI status via `gh`.
    - Once CI completes, **verify tests actually ran:**
      - For unit tests: grep CI logs showing test files were executed.
      - For integration tests: grep CI logs for specific test function names (e.g. `PASS: TestFeatureX`).
    - If tests **pass** → show evidence to the user and exit the loop.
    - If tests **fail:**
      - If failure is **flaky** (infra timeout, rate limit, unrelated test) → rerun via `gh run rerun --failed`.
      - If **unit tests** fail → delegate fix to a code-writer agent → self-review (`pr-correctness` + `pr-architecture`) → push → restart loop.
      - If **integration tests** fail → fix only if the test made a wrong assumption; otherwise fix the implementation → self-review → push → restart loop.
    - Every fix goes through a code-writer agent and self-review — never a hand-edited "quick fix and push."

11. **Escalation — the only sanctioned way to stop while CI is still red.** If all checks cannot be made to pass **without drastic or architectural changes** (redesigning a subsystem, changing a public contract or wire format, or work well outside this PR's scope), do NOT make those changes on your own. Instead:
    - Create the release marker: `touch "$(git rev-parse --git-dir)/ci-loop-escalate"` — this lets the Stop hook release you exactly once.
    - Then stop and tell the user precisely what is blocking, what drastic change would be required, and your recommended options.
    Never silently give up, and never thrash indefinitely. If the 2-hour budget elapses with no path to green, treat it as this escalation case: check in with the user rather than continuing to poll in silence.

12. **Exit condition:** Both unit tests and integration tests pass, with grep evidence shown to the user.

### Rules that apply across all phases

- Skip the worktree step only if the user explicitly overrides.
- Do not trigger this workflow for research, questions, or read-only exploration.
- Every fix iteration (Phase 3 failures) goes through self-review before pushing — no "quick fix and push" shortcuts.
- All code, in every phase (integration tests, implementation, review fixes, CI-failure fixes), goes through a code-writer agent and follows the rules in `~/.claude/rules/`.

## Coding rules

All coding and test rules live in `~/.claude/rules/`:

- `general.md` — language-agnostic rules (abstraction, comments, error handling, scope, test design, and "no over-defensive constructor checks").
- `go.md`, `python.md`, `typescript.md` — per-language specifics (standard-library preferences, test idioms, common pitfalls; e.g. no `ctrl.Finish()` in Go gomock tests).

The `code-writer` / `code-writer-hard` and `pr-correctness` agents read these before working, so the writer and the reviewer enforce the same list. **Add new coding rules there — one place, no drift.**

## Reviewing PRs on GitHub

When the user asks you to review a PR on GitHub (theirs or someone else's), invoke the `pr-review` skill. It runs the diff-review subagents, checks the PR's `## Why`, prefixes every candidate comment with `from Derek's PR Review Agent: `, and runs a confirm-before-post gate.
