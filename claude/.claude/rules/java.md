# Java rules

Read alongside `general.md`. Add new Java rules here.

## Unused code

### Tooling

- Use PMD's unused rules to find genuinely-dead code — they analyze a closed scope, so they're precise: `UnusedPrivateMethod`, `UnusedPrivateField`, `UnusedLocalVariable`, `UnusedFormalParameter`.
- Error Prone's `RemoveUnusedImports` handles unused imports at compile time (with an autofix).
- Do not treat whole-project "unused declaration" scans as authoritative for deletion — anything reachable only via reflection, DI (Spring), or serialization will look unused but isn't. Confirm before removing non-private symbols.
