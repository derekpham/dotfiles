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

## Personal GitHub workflow

Apply this workflow when `gh repo view --json nameWithOwner --jq .nameWithOwner`
starts with `derekpham/`. It is separate from the Roblox workflow below and
does not apply to Roblox repositories.

For any request that writes files:

1. Update `master` or `main`, then create and enter a sibling worktree for a
   new feature branch before editing. Never edit in the primary checkout unless
   the user explicitly overrides this requirement.
2. Make and verify the requested changes in the worktree, then commit them.
3. Push over HTTPS regardless of the configured Git remote:

   ```bash
   repo_url=$(gh repo view --json url --jq .url)
   branch=$(git branch --show-current)
   GIT_CONFIG_GLOBAL=/dev/null git \
     -c credential.helper='!gh auth git-credential' \
     push "${repo_url}.git" "HEAD:refs/heads/${branch}"
   ```

4. When the user requested a PR, use the `pr-create` skill to open a draft with
   `gh pr create --draft`.

Do not trigger this workflow for research, questions, or read-only exploration.

## Roblox coding workflow

Apply this workflow only when the repository is hosted on `github.rbx.com`.
Skip it for personal and public repositories. Personal repositories use the
separate workflow above.

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
