---
name: ship
description: >
  Start the CI-monitoring loop for the current PR and drive it green. Invoke when the
  user says "/ship", "ship it", "monitor CI", "drive CI green", or otherwise signals
  that all the work is done and they want CI watched until it passes. This is the ONLY
  thing that starts CI monitoring — writing tests, implementing, and review cycles never
  monitor on their own. Do NOT use for creating PRs (that's pr-create) or reviewing them.
---

Drive the current PR's CI green. This is the deliberate, final step after all code is written and reviewed.

## 1. Confirm there's something to monitor

From inside the worktree, check the current branch has an open PR:

```bash
gh pr view --json number,state,isDraft
```

- No PR, or PR not `OPEN` → tell the user there's nothing to ship yet (create/push the PR first) and stop. Do not arm.
- PR exists and is `OPEN` → continue. (A draft is fine; monitoring a draft before marking it ready is normal.)

## 2. Arm the loop

Write the current epoch seconds to the active marker in the worktree's git dir. Its presence is what makes the Stop hook (`~/.claude/hooks/ci-loop-guard.sh`) enforce the loop — until now nothing has been enforcing.

```bash
date +%s > "$(git rev-parse --absolute-git-dir)/ci-loop-active"
```

## 3. Run the monitoring loop

Follow **Phase 3** of `~/.claude/CLAUDE.md`:

- Read `.github/workflows/` to learn which jobs run unit vs integration tests and what triggers them (CI is a DAG — not everything is queued immediately).
- Poll `gh pr checks` every ~3 minutes.
- When CI completes, verify tests actually ran (grep logs for executed unit-test files and for specific integration test function names, e.g. `PASS: TestFeatureX`).
- If checks **pass** → remove the marker (`rm -f "$(git rev-parse --absolute-git-dir)/ci-loop-active"`), show the grep evidence to the user, and stop. (The Stop hook also clears the marker on green; removing it explicitly is belt-and-suspenders.)
- If checks **fail:**
  - Flaky (infra timeout, rate limit, unrelated test) → `gh run rerun --failed`.
  - Unit-test failure → delegate the fix to a code-writer agent → self-review (`pr-correctness` + `pr-architecture`) → push → **re-arm** (step 4) → keep polling.
  - Integration-test failure → fix only if the test made a wrong assumption; otherwise fix the implementation → self-review → push → **re-arm** → keep polling.

## 4. Re-arm on every push during the loop

After each fix-push, refresh the marker so the loop's stale-timeout budget resets:

```bash
date +%s > "$(git rev-parse --absolute-git-dir)/ci-loop-active"
```

## 5. Exit conditions

- **Green:** both unit and integration tests pass with grep evidence → disarm and report. Done.
- **Stuck:** if CI cannot be made green without drastic/architectural changes (redesigning a subsystem, changing a public contract or wire format, or work far outside this PR's scope), do NOT make those changes yourself. Create the one-shot release marker, then stop and explain the blocker and your recommended options:

  ```bash
  touch "$(git rev-parse --absolute-git-dir)/ci-loop-escalate"
  ```

- **User calls it off:** if the user asks you to stop monitoring and just discuss the code, remove the active marker and stop:

  ```bash
  rm -f "$(git rev-parse --absolute-git-dir)/ci-loop-active"
  ```

Never silently give up, and never thrash indefinitely.
