---
name: pr-review
description: Review a GitHub pull request with parallel correctness and architecture agents, then present exact inline comments for approval before posting.
---

Identify the PR from the supplied URL or number, or from the current branch.

Spawn `pr_correctness` and `pr_architecture` in parallel and wait for both.
Separately read the PR title and body and verify that a leading `## Why` section
explains the motivation rather than merely restating the diff.

Summarize what the change does and how it works, then aggregate only supported
findings. Every candidate comment must:

- Cite a changed file and line that accepts an inline GitHub comment.
- Include a short surrounding code snippet.
- Begin with `from Derek's PR Review Agent: `.

Show the numbered candidate comments and wait for the user's explicit approval
of which comments to post. A prior request to review is not permission to post.
Post only approved comments as inline review comments. Approve or request
changes only when the user explicitly authorizes that verdict.
