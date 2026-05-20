---
name: pr-create
description: >
  Use this skill whenever the user wants to draft, open, create, send, or submit a pull request (e.g. "open a PR", "draft a PR", "make a PR", "ship this as a PR", "gh pr create"). Enforces a Why-first PR description format: the skill asks the human for the motivation before writing anything, then drafts a title and body in their words and creates the PR as a draft via `gh pr create --draft`.
---

Open a pull request the way Derek wants them opened.

## 1. Ask why first — wait for the answer

Before drafting the title or body, use `AskUserQuestion` to ask the human: **why is this change necessary?**

Do **not** infer the motivation from the diff, branch name, or commit messages. The whole point of this skill is that the diff already explains *what*; only the human can explain *why*. The user's answer becomes the foundation of both the title and the `## Why` section.

If the user volunteered a clear, specific motivation earlier in this same conversation, you can skip the question and use that. When in doubt, ask.

## 2. Title

The title must summarize **both the why and the how** in under ~70 characters. The motivation half comes from the user's answer; the implementation half can come from the diff.

- Good: "Drop nil checks in config loader so bad inputs fail loudly"  *(why + how)*
- Bad: "Refactor config loader"  *(how only)*
- Bad: "Make config loading better"  *(neither half is specific)*

## 3. Body

The body **must** begin with `## Why`. Use the user's words, not your paraphrase.

```markdown
## Why
<the user's motivation, in their words>
```

Skip `## Summary` and `## Test plan` unless they add information the diff doesn't already convey:

- A manual test that ran outside CI.
- A non-obvious behavior change a reviewer would miss from the diff alone.
- A follow-up that's intentionally out of scope.

If they don't add anything, omit them. The `## Why` is the section that earns its space.

## 4. Always create as a draft

Use `gh pr create --draft …`. Do not ask permission to draft — just draft it. The user marks the PR ready for review themselves when they're ready.

Pass the body via heredoc to preserve formatting:

```bash
gh pr create --draft --title "…" --body "$(cat <<'EOF'
## Why
…
EOF
)"
```

Return the PR URL when done.
