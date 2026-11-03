# User-level instructions

## Coding workflow (personal projects)

**Scope:** Applies when the current repo's git remote does **not** point to `github.rbx.com` (personal github.com repos). Check with `git remote -v` if unsure. For Roblox remotes, use the Roblox workflow below instead.

**DO NOT edit on `master`/`main`.** Enter a worktree first. When the work is done, open a PR from that worktree and paste the PR link so it can be reviewed. Do not push `master`/`main`.

For any session where the user asks to write code in a personal project:

1. Run `git fetch origin` to refresh `origin/master` / `origin/main`. Do not check out or pull `master`/`main` in the shared checkout — it switches the branch out from under other sessions and can merge or conflict.
2. If cwd is not already under `.claude/worktrees/`, enter a new worktree via `EnterWorktree` (it branches from `origin/<default-branch>`) before making changes. Background sessions (`claude agents`) already enforce this. Skip the worktree only if the user explicitly overrides.
3. Do the work in the worktree. Verify before treating it as done.
4. Push the worktree branch and open a draft PR with the `pr-create` skill. Do not squash-merge or push to `master`/`main`.
5. **Paste the PR URL in the reply and stop for review.** Do not mark the PR ready, merge it, or watch CI unless the user asks.

Push with `git push -u origin HEAD`. Claude Code's worktree isolation refuses
git commands that set `GIT_CONFIG_GLOBAL` or redirect into the git dir, so keep
git invocations plain and run them one at a time.

**SSH git often fails in the Cursor agent sandbox** (`kex_exchange_identification`, `banner exchange`, `Network is down`) even while the user's own terminal can pull/push and `gh` / HTTPS still work. Do not tell the user to push, and do not treat a failed `git fetch` as proof that `origin/main` is current.

Only when SSH fails outside a Claude Code worktree: a global `url.ssh://git@github.com/.insteadOf https://github.com/` rewrite sends plain HTTPS remotes back over SSH, so disable the global rewrite for the command and use `gh` as Git's credential helper:

```bash
repo_url=$(gh repo view --json url --jq .url)
branch=$(git branch --show-current)
GIT_CONFIG_GLOBAL=/dev/null git \
  -c credential.helper='!gh auth git-credential' \
  push "${repo_url}.git" "HEAD:refs/heads/${branch}"
```

Then create the draft PR with `gh` as usual. If the user's statement about Git
state contradicts local refs, refresh them over HTTPS with the same credential
helper before answering.

After the draft PR is created, and after every later successful push, arm safe
session-end cleanup by recording the pushed commit in a per-worktree ref:

```bash
git update-ref refs/worktree/cleanup-armed HEAD
```

The `SessionEnd` hook removes the worktree only when it is clean and still at
that exact commit. It never uses `--force`; if verification fails, leave the
worktree intact.

Do not trigger this workflow for research, questions, or read-only exploration.

## Coding workflow (Roblox projects only) — DO THIS FIRST

**Scope:** Applies when the current repo's git remote points to `github.rbx.com`. Check with `git remote -v` if unsure; skip this workflow for non-Roblox repos. Personal repositories use the separate workflow above.

**DO NOT edit, write, or create any file before completing steps 1–2. DO NOT skip the worktree — editing files on master is never acceptable unless the user explicitly says so.**

**DO NOT write code directly.** All code and test changes — including small iterative fixes — must be delegated to the `code-writer` agent (or `code-writer-hard` for genuinely hard tasks: subtle concurrency, tricky algorithms, large multi-file changes). The main loop must never use Write/Edit on source files. The code-writer agents have their own rules for test coverage and conventions — do not override them. Describe the goal and provide context (relevant files, patterns, constraints), but do NOT enumerate implementation steps or specify test file names.

**Exception — trivial changes.** Typos, comment or doc edits, renames, a constant or config value, or a one-line fix with no new behavior may be edited directly by the main loop, and skip Phase 1 planning. Everything else still applies: worktree, self-review (step 5), `pr-create`, and `/ship`. If the change grows beyond trivial, stop editing and go back to the normal flow.

**CI monitoring is never automatic.** Writing tests, implementing, pushing, and review cycles never watch CI on their own. The CI-monitoring loop runs only when the user invokes the `/ship` command (Phase 3). `/ship` covers only the current PR. Until then, you always stop cleanly for the user to review.

For any new session where the user asks to write code:

### Phase 0: Setup

1. Run `git fetch origin` to refresh `origin/master` / `origin/main`. Do not check out or pull `master`/`main` in the shared checkout.
2. If cwd is not already under `.claude/worktrees/`, enter a new worktree via `EnterWorktree` (it branches from `origin/<default-branch>`) before making changes. Background sessions (`claude agents`) already enforce this.

### Phase 1: Plan

3. **Plan the work with the `design-architect` agent.** Even if the user says "implement X," plan first. Give it the task and context. It sets the overall direction for the whole task, then breaks it into an ordered sequence of PRs following its "PR breakdown rules" (smallest behavior change per PR, no dead code, ~300–400 lines excluding tests, generated code, and spec files). For each PR the plan also states whether it needs integration tests: check whether existing integration tests cover the area, and if the feature area has none, ask the user whether they want them. Integration tests land in the PR whose behavior they cover, not up front.
   - Present the plan to the user for approval before proceeding.

### Phase 2: One PR at a time

Repeat steps 4–7 for each PR in the approved plan, in order. Start the next PR only when the user says so. If the previous PR hasn't merged yet, branch the next one from it.

4. Delegate the PR's scope from the plan to the `code-writer` agent (or `code-writer-hard` for genuinely hard tasks). The code-writer will follow its own rules for:
   - Writing unit tests for all new/changed exported methods.
   - Full branch coverage of new code paths (unless awkward to achieve — e.g. platform-specific error paths, unreachable defensive branches).
   - Behavior-based assertions, not implementation-detail assertions.
   - Integration tests, if the plan calls for them in this PR:
     - Test at public boundaries only: API endpoints, CLI output, exported package interfaces, database state, HTTP responses.
     - **Never** assert on internal function calls, struct layouts, dependency wiring, or implementation details.
     - Tests **must not break** on code refactors or architecture refactors (unless the requested change is itself architectural).
   - Integration tests from earlier PRs must continue to pass without modification (unless they made a wrong assumption).

5. **Self-review before pushing.** Run `pr-correctness` and `pr-architecture` subagents on the diff. Both must verify:
   - All new exported methods have unit tests.
   - Coverage of new code paths is complete (flag gaps explicitly).
   - Unit tests assert on behavior, not implementation.
   - The PR adds no dead code and stays within the plan's scope for it.
   - Existing integration tests were not modified (unless a wrong assumption was identified).

6. Before creating the first PR, ask the user for a Jira ticket number (e.g. `PROJ-123`). If there is no ticket, use `ADHOC`. Include the ticket in the PR title as a prefix. Reuse it for later PRs in the plan unless the user says otherwise.

7. When opening the PR, invoke the `pr-create` skill — it asks the human for the *why*, drafts a `## Why`-first body, and creates the PR as a draft. Then **stop for review.** Do not monitor CI yet — expect one or more review cycles (delegate every fix to a code-writer agent + self-review). CI monitoring starts only when the user runs `/ship`.

### Phase 3: Ship — CI monitoring loop for a single PR (runs ONLY when the user invokes `/ship`)

> **Enforced by a Stop hook, but only while a loop is *armed*.** Nothing here runs until the user invokes the `/ship` skill. `/ship` arms a `ci-loop-active` marker (an epoch timestamp) in the worktree's git dir. While that marker is live *and* the branch's open PR has pending/failing checks, `~/.claude/hooks/ci-loop-guard.sh` **blocks you from ending your turn** and tells you to resume this loop. The marker — and the block — clears automatically when CI goes green, the PR closes, or the marker goes stale (older than the hook's TTL, a safety net for an abandoned loop). So plain chat, code-improvement discussions, test/implementation/review work, and stale branches are never blocked. The only sanctioned exits while CI is red are the exit condition (all green, step 11) and escalation (step 10). If the user asks you to stop monitoring, remove the marker (`rm -f "$(git rev-parse --absolute-git-dir)/ci-loop-active"`) and stop.

The `/ship` skill walks you through the following; this is the canonical procedure it points to:

8. **Read `.github/workflows/`** to understand which workflows run unit tests and integration tests. CI is a DAG — not all jobs are queued right away. Some workflows:
   - Depend on other workflows completing first (e.g. `workflow_run`, `needs:`).
   - Only run on specific path filters.
   - Are gated behind labels or manual triggers.
   You must read the repo's workflow files to know which job names to wait for and what triggers them. Don't assume all checks appear instantly or that an empty checks list means "nothing to run."

9. **Monitor** (poll every 3 minutes; re-arm the marker on each push so the stale-timeout budget resets):
    - Check the PR's CI status via `gh`.
    - Once CI completes, **verify tests actually ran:**
      - For unit tests: grep CI logs showing test files were executed.
      - For integration tests: grep CI logs for specific test function names (e.g. `PASS: TestFeatureX`).
    - If tests **pass** → show evidence to the user and exit the loop.
    - If tests **fail:**
      - If failure is **flaky** (infra timeout, rate limit, unrelated test) → rerun via `gh run rerun --failed`.
      - If **unit tests** fail → delegate fix to a code-writer agent → self-review (`pr-correctness` + `pr-architecture`) → push → re-arm → restart loop.
      - If **integration tests** fail → fix only if the test made a wrong assumption; otherwise fix the implementation → self-review → push → re-arm → restart loop.
    - Every fix goes through a code-writer agent (unless trivial — see the exception above) and self-review — never an unreviewed "quick fix and push."

10. **Escalation — the only sanctioned way to stop while CI is still red.** If all checks cannot be made to pass **without drastic or architectural changes** (redesigning a subsystem, changing a public contract or wire format, or work well outside this PR's scope), do NOT make those changes on your own. Instead:
    - Create the release marker: `touch "$(git rev-parse --absolute-git-dir)/ci-loop-escalate"` — this lets the Stop hook release you exactly once and stands down the loop. (Run it from inside the worktree.)
    - Then stop and tell the user precisely what is blocking, what drastic change would be required, and your recommended options.
    Never silently give up, and never thrash indefinitely.

11. **Exit condition:** Unit tests and the PR's integration tests (if any) pass, with grep evidence shown to the user.

### Rules that apply across all phases

- Skip the worktree step only if the user explicitly overrides.
- Do not trigger this workflow for research, questions, or read-only exploration.
- Every fix iteration goes through self-review before pushing — no "quick fix and push" shortcuts.
- All code, in every phase (implementation, integration tests, review fixes, CI-failure fixes), goes through a code-writer agent (except trivial changes) and follows the rules in `~/.claude/rules/`.

### CI-loop marker files (quick reference)

Both live in the worktree's git dir (`$(git rev-parse --absolute-git-dir)`):

- `ci-loop-active` — **armed by `/ship`.** Contains an epoch timestamp; its presence is what makes the Stop hook enforce the loop. Re-armed on each push during the loop (resets the stale timeout). Cleared automatically when CI goes green, the PR closes, or it goes stale. Delete it to stop monitoring and just discuss the code.
- `ci-loop-escalate` — **one-shot.** Releases the Stop hook a single time when a PR can't go green without drastic changes; also stands down the active loop. The hook consumes (deletes) it.

## Coding rules

All coding and test rules live in `~/.claude/rules/`:

- `general.md` — language-agnostic rules (abstraction, comments, error handling, scope, test design, and "no over-defensive constructor checks").
- `go.md`, `python.md`, `typescript.md` — per-language specifics (standard-library preferences, test idioms, common pitfalls; e.g. no `ctrl.Finish()` in Go gomock tests).

The `code-writer` / `code-writer-hard` and `pr-correctness` agents read these before working, so the writer and the reviewer enforce the same list. **Add new coding rules there — one place, no drift.**

## Reviewing PRs on GitHub

When the user asks you to review a PR on GitHub (theirs or someone else's), invoke the `pr-review` skill. It runs the diff-review subagents, checks the PR's `## Why`, prefixes every candidate comment with `from Derek's PR Review Agent: `, and runs a confirm-before-post gate.

## General stuff
Reply as concisely as possible. Skip pleasantries, preambles, and recaps of my question. Avoid phrases like "I'd be happy to," "Great question," or "let me explain." Drop articles and filler words where meaning stays clear. Prefer short, declarative sentences. If a tool call is needed, run it first and show only the result. Do not narrate your steps unless explicitly stated.
