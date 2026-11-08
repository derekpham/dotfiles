# User-level instructions

## Coding workflow — DO THIS FIRST

**Scope:** Applies to every repo when the user asks to write code. Do not trigger it for research, questions, or read-only exploration. Rule files in `~/.claude/rules/` may add steps for specific repos (check `git remote -v`); follow them where they apply. Personal repos (`github.com` remotes) have their own push fallback and worktree cleanup (see "Personal repos: pushing and cleanup").

**DO NOT edit, write, or create any file before completing steps 1–2. DO NOT skip the worktree — editing files on `master`/`main` is never acceptable unless the user explicitly says so. Never push `master`/`main`.**

**DO NOT write code directly.** All code and test changes — including small iterative fixes — must be delegated to the `code-writer` agent (or `code-writer-hard` for genuinely hard tasks: subtle concurrency, tricky algorithms, large multi-file changes). The main loop must never use Write/Edit on source files. The code-writer agents have their own rules for test coverage and conventions — do not override them. Describe the goal and provide context (relevant files, patterns, constraints), but do NOT enumerate implementation steps or specify test file names.

**Exception — trivial changes.** Typos, comment or doc edits, renames, a constant or config value, or a one-line fix with no new behavior may be edited directly by the main loop, and skip Phase 1 planning. Everything else still applies: worktree, self-review (step 5), and `pr-create`. If the change grows beyond trivial, stop editing and go back to the normal flow.

**CI monitoring is never automatic.** Writing tests, implementing, pushing, and review cycles never watch CI on their own. Watch CI only when the user asks. Until then, you always stop cleanly for the user to review.

### Phase 0: Setup

1. Run `git fetch origin` to refresh `origin/master` / `origin/main`. Do not check out or pull `master`/`main` in the shared checkout — it switches the branch out from under other sessions and can merge or conflict.
2. If cwd is not already under `.claude/worktrees/`, enter a new worktree via `EnterWorktree` (it branches from `origin/<default-branch>`) before making changes. Background sessions (`claude agents`) already enforce this.

### Phase 1: Plan

3. **Plan the work with the `design-architect` agent.** Even if the user says "implement X," plan first. Give it the task and context. It sets the overall direction for the whole task, then breaks it into an ordered sequence of PRs following its "PR breakdown rules" (smallest behavior change per PR, no dead code, ~300–400 lines excluding tests, generated code, and spec files). For each PR the plan also states whether it needs integration tests: check whether existing integration tests cover the area, and if the feature area has none, ask the user whether they want them. Integration tests land in the PR whose behavior they cover, not up front.
   - Present the plan to the user for approval before proceeding.
   - Once approved, save the plan where a fresh session can pick it up: as checklist items and decisions in the repo's feature doc if one exists, otherwise in memory. Then suggest `/clear` before implementing. Run one session per plan item (sub-feature), and suggest `/clear` again whenever review rounds have made a session long — the feature doc and memory carry the context forward.

### Phase 2: One PR at a time

Repeat steps 4–6 for each PR in the approved plan, in order. Start the next PR only when the user says so. If the previous PR hasn't merged yet, branch the next one from it.

4. Delegate the PR's scope from the plan to the `code-writer` agent (or `code-writer-hard` for genuinely hard tasks). Keep the brief to the goal, constraints, and anything not yet written down; point to the feature doc or saved plan for the rest instead of restating it. The code-writer will follow its own rules for:
   - Writing unit tests for all new/changed exported methods.
   - Full branch coverage of new code paths (unless awkward to achieve — e.g. platform-specific error paths, unreachable defensive branches).
   - Behavior-based assertions, not implementation-detail assertions.
   - Integration tests, if the plan calls for them in this PR:
     - Test at public boundaries only: API endpoints, CLI output, exported package interfaces, database state, HTTP responses.
     - **Never** assert on internal function calls, struct layouts, dependency wiring, or implementation details.
     - Tests **must not break** on code refactors or architecture refactors (unless the requested change is itself architectural).
   - Integration tests from earlier PRs must continue to pass without modification (unless they made a wrong assumption).

5. **Self-review before pushing.** Scale the review to the change:
   - **Docs, config, or assets only** (no code): review the diff yourself; no subagents.
   - **Under ~150 changed lines, not touching auth, storage, crypto, network, or concurrency:** run `pr-correctness` alone; it also covers the architecture basics.
   - **Everything else:** run both `pr-correctness` and `pr-architecture`.

   The reviews must verify:
   - All new exported methods have unit tests.
   - Coverage of new code paths is complete (flag gaps explicitly).
   - Unit tests assert on behavior, not implementation.
   - The PR adds no dead code and stays within the plan's scope for it.
   - Existing integration tests were not modified (unless a wrong assumption was identified).

6. When opening the PR, invoke the `pr-create` skill — it asks the human for the *why*, drafts a `## Why`-first body, and creates the PR as a draft. Paste the PR URL and **stop for review.** Do not mark the PR ready, merge it, or monitor CI — expect one or more review cycles (delegate every fix to a code-writer agent + self-review).

### Rules that apply across all phases

- Skip the worktree step only if the user explicitly overrides.
- Every fix iteration goes through self-review before pushing — no "quick fix and push" shortcuts.
- All code, in every phase (implementation, integration tests, review fixes, CI-failure fixes), goes through a code-writer agent (except trivial changes) and follows the rules in `~/.claude/rules/`.
- One-off subagents you launch yourself (security reviews, false-positive checks, lookups) run with `model: sonnet`, unless the change touches auth, storage, or crypto.
- Each repo's `CLAUDE.md` keeps a short code map (top-level areas and key files, one line each) so agents spend less time exploring. Update it in the PR that adds or moves a key file.

### Personal repos: pushing and cleanup

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

## Coding rules

All coding and test rules live in `~/.claude/rules/`:

- `general.md` — language-agnostic rules (abstraction, comments, error handling, scope, test design, and "no over-defensive constructor checks").
- `go.md`, `python.md`, `typescript.md`, `android.md` (Kotlin/Android) — per-language specifics (standard-library preferences, test idioms, common pitfalls; e.g. no `ctrl.Finish()` in Go gomock tests).

The `code-writer` / `code-writer-hard` and `pr-correctness` agents read these before working, so the writer and the reviewer enforce the same list. **Add new coding rules there — one place, no drift.**

## Reviewing PRs on GitHub

When the user asks you to review a PR on GitHub (theirs or someone else's), invoke the `pr-review` skill. It runs the diff-review subagents, checks the PR's `## Why`, prefixes every candidate comment with `from Derek's PR Review Agent: `, and runs a confirm-before-post gate.

## General stuff
Reply as concisely as possible. Skip pleasantries, preambles, and recaps of my question. Avoid phrases like "I'd be happy to," "Great question," or "let me explain." Drop articles and filler words where meaning stays clear. Prefer short, declarative sentences. If a tool call is needed, run it first and show only the result. Do not narrate your steps unless explicitly stated.
