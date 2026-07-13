# General coding rules (language-agnostic)

These rules apply to every language. Per-language specifics live alongside this file in `go.md`, `python.md`, `typescript.md`. Both the `code-writer` / `code-writer-hard` agents and the `pr-correctness` reviewer read these, so the writer and the reviewer enforce the same list. Add new cross-language rules here.

## Don't over-abstract

- No interface with one implementation. No generic helper with one caller. No config knob for a value that never varies.
- Three similar lines is fine. Copy-paste is fine at two call sites. **Only extract a helper when the same logic appears in more than two places.** Two instances is a coincidence; three is a pattern.
- No speculative parameters for "future flexibility." Add them when a second caller needs them.
- No wrapping a working library call in your own function just to rename it.

## Use the standard library and existing helpers

Before writing a loop or a conditional, check whether the language or codebase already solves it. See the per-language file for the specific built-ins to reach for. If you find yourself writing an if/else chain that picks a max, a for-loop that checks membership, or a manual group-by, stop and use the built-in.

Also check the repo: there's often already a logger, config loader, HTTP client, retry helper, or test fixture. Import it. Don't reinvent.

## No over-defensive constructor checks

Skip precondition checks that either (a) duplicate a clear error the caller would get anyway from downstream code, or (b) silently coerce invalid input to a "sensible default."

Examples of checks to **not** add:

- `if fileName == "" { return err }` when `os.Open` / `os.ReadFile` / etc. will fail with a clear error on the next line.
- `if interval <= 0 { interval = defaultInterval }` — silent coercion conflates "caller forgot to set it" with "caller explicitly passed 0" and papers over both.
- Nil checks on arguments that the caller is *expected* to pass — let the nil deref happen loudly rather than swapping in a silent fallback.

Enforce these invariants via unit tests instead — write tests that pass invalid config/args and assert the expected failure. This catches misuse at development time without runtime overhead or silent fallbacks.

How to decide: "If I remove this check, what does the caller see?" If the error is already clear (downstream `os` call fails, `time.NewTicker(0)` panics, etc.), the check is redundant — drop it.

If `0` / `""` / `nil` is meant as "use the default," use `*T`, an options struct, or a constructor that doesn't require it — so "not specified" is distinguishable from "explicitly invalid."

Exception: trust boundaries (user input, network APIs, parsing untrusted data). Validation there is legitimate.

## Comments

Default: don't write one.

Write a comment only when the *why* is non-obvious and would surprise a future reader:

- A non-obvious constraint or invariant ("must run before X because Y")
- A workaround for a specific bug, with a link or reason
- A deliberate deviation from the obvious approach, with the reason

Do not write:

- Comments that restate what the code does. `// increment i` is noise.
- Comments that reference the current task, ticket, or author.
- Multi-line preambles on functions whose name and signature already describe the behavior.
- Section banners (`// === Helpers ===`).

## Error handling

- Only handle errors you can meaningfully act on. Propagate the rest.
- When propagating, wrap with context so the final message traces where it came from. Skip wrapping only if the caller already has the same context.
- Don't add defensive checks for conditions internal code guarantees. Validate only at real boundaries: user input, network, disk, untrusted callers.
- Don't swallow errors silently. If you're intentionally ignoring one, the reason belongs in a comment (this is the rare case where a comment is warranted).

## Scope

- Do exactly what the task asks. No drive-by refactors, no renaming unrelated symbols, no reformatting untouched files.
- If you notice something broken or ugly nearby, note it in your final report — don't fix it inline.

## Tests

Tests exist to catch regressions in *behavior*, not to lock in *implementation*. A good test passes after a refactor that preserves behavior and fails when behavior changes.

### Test behavior, not implementation

- Assert on observable outputs: return values, side effects a caller can see, errors raised.
- Don't assert on internal call counts, private field values, or the exact sequence of internal steps, unless the contract genuinely requires them.
- Don't mock what you don't need to mock. Prefer real collaborators when they're cheap (in-memory stores, local filesystems in temp dirs).
- If the test needs to know about private internals to work, the test is wrong — or the API is.

### Keep tests simple

A test should read top-to-bottom as: arrange, act, assert. Branching and loops inside a test body obscure that shape.

- No `if`/`else` inside a test case to pick different assertions for different inputs. The only acceptable branch is `if err != nil` vs the success path (or the language equivalent).
- No loops inside a test case, other than the outer loop of a table-driven test that delegates each row to a subtest.
- No shared mutable state between cases. Each case sets up what it needs.
- No helper functions that themselves contain `if`/`else` over test behavior. Helpers may set up fixtures; they must not decide what the test asserts.

### Prefer table-driven / parameterized tests

When several cases share the same arrange/act/assert shape, use one test with a table of inputs and expected outputs. See the per-language file for the idiom. If a case needs fundamentally different setup or assertions, lift it out into its own test instead of shoehorning it into the table.

### Assert on error type, not message text

Prefer type/sentinel assertions (e.g. `errors.Is` / `errors.As`) over substring matching on the error message. String-matching couples the test to the exact wording of an error message; rewording it then breaks unrelated tests. Reach for substring matching only when a type assertion would be contrived.

### Coverage

- Cover the happy path, the main error paths, and any boundary that can realistically break (empty input, nil, zero, max, off-by-one).
- Don't chase 100% coverage by testing trivial getters or generated code.
- New behavior → new tests in the same PR. A change with no test is incomplete unless the task explicitly says otherwise.
