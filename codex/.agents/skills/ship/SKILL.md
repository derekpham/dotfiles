---
name: ship
description: Monitor the current pull request and drive CI green after implementation and review are complete. Use only when the user says ship, monitor CI, or drive CI green.
---

Confirm the current branch has an open PR. If it does not, report that there is
nothing to monitor and stop.

Arm the CI loop:

```bash
date +%s > "$(git rev-parse --absolute-git-dir)/ci-loop-active"
```

Read `.github/workflows/` to learn the actual unit and integration jobs,
dependencies, path filters, labels, and manual gates. Poll the PR checks about
every three minutes. When checks complete, verify from logs that the expected
unit and integration tests actually ran.

If a failure is unrelated infrastructure flakiness, rerun only the failed
jobs. For code or test failures, delegate the fix to `code_writer` or
`code_writer_hard`, run `pr_correctness` and `pr_architecture` in parallel,
resolve substantive findings, push, refresh the marker, and resume monitoring.

On success, remove `ci-loop-active` and report evidence. If making CI green
would require a drastic architectural or scope change, create
`ci-loop-escalate`, explain the blocker and options, and stop. If the user asks
to stop monitoring, remove `ci-loop-active` and stop.
