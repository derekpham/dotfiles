# User-level instructions

## Communication

- Lead with the outcome and keep explanations concise.
- Make reasonable assumptions when they do not materially change the result.
- Report what changed, what was verified, and anything deliberately left out.

## Coding rules

Before changing code or tests, read `~/.claude/rules/general.md` and every
applicable language file under `~/.claude/rules/`. Those files are the shared
source of truth for both Claude and Codex. Follow repository conventions when
they are more specific.

## Roblox coding workflow

Apply this workflow only when the repository is hosted on `github.rbx.com`.
Skip it for personal and public repositories.

1. Start from an up-to-date `master` or `main` branch and create a separate
   worktree before editing. Never edit the primary branch unless the user
   explicitly requests it.
2. Plan first. Cover the reason for the change, affected packages, and whether
   existing integration tests cover the behavior. For a new feature without
   integration coverage, ask whether the user wants integration tests.
3. Present the plan and wait for approval before implementation.
4. Delegate all code and test changes to `code_writer`, or to
   `code_writer_hard` for subtle concurrency, difficult algorithms, or large
   multi-file changes.
5. If integration tests are requested, write them first at public boundaries,
   open a draft test-only PR, and wait for approval before implementation.
6. Before pushing implementation, run `pr_correctness` and `pr_architecture`
   in parallel. Resolve substantive findings through the appropriate writer
   agent, then repeat review.
7. Ask for a Jira ticket before creating the implementation PR. Use `ADHOC`
   when there is no ticket, and prefix the PR title with it.
8. Use the `pr-create` skill to open a draft PR, then stop for review. Never
   monitor CI automatically.

## CI monitoring

Only start CI monitoring when the user invokes `ship` or explicitly asks to
drive CI green. Follow the `ship` skill. Every code fix must go through a writer
agent and the two review agents before pushing.

## Pull-request review

When asked to review a GitHub pull request, use the `pr-review` skill. Do not
post review comments until the user explicitly approves the exact comments.
