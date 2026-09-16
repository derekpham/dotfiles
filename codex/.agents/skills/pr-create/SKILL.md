---
name: pr-create
description: Create or draft a pull request using Derek's Why-first format. Use whenever the user asks to open, create, submit, or draft a PR.
---

Open a pull request as a draft.

## Motivation

Before drafting, determine why the change is necessary. If the user already
gave a clear, specific motivation in this conversation, use their wording.
Otherwise ask one concise question and wait. Do not infer motivation solely
from the diff, branch name, or commits.

## Title and body

- Keep the title under about 70 characters and summarize both why and how.
- Preserve a requested Jira prefix such as `PROJ-123` or `ADHOC`.
- Begin the body with `## Why`, using the user's words.
- Follow with `## How`, using one short paragraph or one to three bullets.
- Add testing or follow-up sections only when they convey information not
  obvious from the diff.

For a personal repository whose `nameWithOwner` reported by `gh repo view`
starts with `derekpham/`, push the current branch over HTTPS rather than through
the configured SSH remote:

```bash
repo_url=$(gh repo view --json url --jq .url)
branch=$(git branch --show-current)
git push "${repo_url}.git" "HEAD:refs/heads/${branch}"
```

This HTTPS rule applies only to personal repositories. Leave the existing
Roblox push workflow unchanged.

Before creating the PR, inspect the branch diff and verify the title/body match
it. Create it with `gh pr create --draft`, preserving Markdown formatting, and
return the PR URL. Do not start monitoring CI.
