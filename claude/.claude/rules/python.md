# Python rules

Read alongside `general.md`. Add new Python rules here.

## Unused code

### Tooling

- Use `ruff` to find and remove genuinely-dead code: `F401` (unused imports) and `F841` (unused local variables). Both are precise, and `ruff check --fix` deletes them automatically.
- These cover the common cases a change leaves behind. Do not rely on heuristic whole-project dead-code scanners (e.g. `vulture`) for deletion — they false-positive on dynamic dispatch, framework hooks, and reflection.
