---
name: pr-review
description: >
  Use this skill whenever the user asks you to review a pull request — theirs or someone else's. Triggers on phrases like "review this PR", "review PR #123", "do a PR review on <url>", "look over this PR for me". The skill fans out to the `pr-correctness` and `pr-architecture` subagents for the diff review, separately checks the PR's `## Why` section, aggregates findings under Derek's attribution prefix, and runs a confirm-before-post gate before any comment hits GitHub.
---

Review a PR the way Derek reviews them on GitHub.

## 1. Identify the PR

From a URL, a number, or the current branch (`gh pr view`). If ambiguous, ask the user which PR.

## 2. Fan out to the diff-review subagents in parallel

In a single message with two `Agent` tool calls, invoke:

- `pr-correctness` — bugs, error handling, test coverage, language-specific issues.
- `pr-architecture` — design, abstractions, module boundaries, fit with existing patterns.

Run them in parallel; they're independent. Each subagent reads the diff itself; you don't need to pre-summarize it.

## 3. Summarize the change for Derek

After the subagents finish, write a short summary (3–6 sentences) covering:

- **What** the change does (the observable behavior or outcome).
- **How** it achieves it (key implementation approach — new files, modified paths, patterns used).

Present this summary to the user before the list of findings so he can orient himself in the diff quickly. Keep it factual — no opinions or recommendations here.

## 4. Check the `## Why` yourself

Separately, read the PR title and body via `gh pr view <pr>`. Ask:

- Does the body have a `## Why` section at the top?
- Does it explain the **motivation** (the reason this change is necessary), not just restate what the diff does?
- Is it vague ("clean up things", "improve X") in a way a reviewer can't act on?

If any of those fail, that's a finding — flag it as a review comment alongside the subagent findings.

## 5. Aggregate findings, prefix every comment

Combine the two subagent outputs and the `## Why` check into a single list of candidate comments. **Every** candidate comment must start with the literal prefix:

```
from Derek's PR Review Agent: 
```

…so it's clearly attributed when posted.

**All comments must be inline (pinpointed to specific code lines).** Do not post general PR-level comments. Every finding — including the missing `## Why` flag — must be tied to a file and line number.

If the PR is missing a `## Why` section, post that comment as an inline comment on the **first changed line** of the diff (first file, first hunk, first `+` line).

## 6. Confirm before posting — never auto-post

Show the candidate comments to the user and ask which ones to actually post. Present them as a numbered list. For each comment, include:

- The **file path and line number** where it will be posted.
- A **code snippet** showing the relevant lines (a few lines of context around the target line).
- The **comment text** that will be posted.

This lets the user see exactly where each comment lands before approving.

Do **not** post anything until the user has explicitly confirmed which comments to include. "Looks good" or "review the PR" earlier in the conversation does **not** count as approval to post — this gate is mandatory every time.

## 7. Post the approved comments

After confirmation, post all comments as **inline comments** pinpointed to specific lines:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  -f body="from Derek's PR Review Agent: …" \
  -f commit_id=<sha> -f path=<file> -F line=<n> -f side=RIGHT
```

- `gh pr review --request-changes` / `--approve` only if the user explicitly confirmed the verdict.

Return links to the posted comments.
