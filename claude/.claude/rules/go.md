# Go rules

Read alongside `general.md`. Add new Go rules here.

## Prefer the standard library over hand-rolled

- `min`, `max` (Go 1.21+ builtins) instead of if/else comparisons.
- `slices.Contains(s, v)` instead of a `for` loop with an equality check.
- `slices.Index`, `slices.Sort`, `maps.Keys`, `maps.Values` rather than manual loops.
- `strings.Cut` instead of `strings.Split` when you only need two parts.
- `errors.Is` / `errors.As` instead of `==` comparison or type assertion on errors.
- Also reach for: `cmp.Or`, `sync.OnceFunc`, `errgroup`, `context`.

## Error handling

- Wrap propagated errors with context: `fmt.Errorf("reading config: %w", err)`.

## Common pitfalls

- Taking the address of a range variable inside a loop (Go 1.22+ fixed this, but flag it on older modules).
- Shadowing variables with `:=` inside `if`/`for` when the outer-scope variable was intended.
- Goroutines that capture loop variables by reference.
- `defer` inside a loop when the deferred call should happen per iteration (use a wrapping function).
- Missing `context.Context` propagation in functions that do I/O.

## Unused code

- Flag unused variables the compiler won't catch: unused struct fields, unused return values that should be checked, dead branches.
- Function parameters that are unused should be named `_` rather than given a real name. Example: `func (s *Server) Handle(_ context.Context, req *Request)` — not `ctx context.Context` when `ctx` is never used.

## Tests

- Prefer table-driven tests: `tests := []struct{ name string; ...; want ... }{ ... }` then `for _, tc := range tests { t.Run(tc.name, func(t *testing.T) { ... }) }`.
- Table-driven tests must NOT branch on test name. Never write:
  ```go
  for _, tc := range tests {
      if tc.name == "special case" {
          // special setup
      }
  }
  ```
  Each case must be self-contained — put setup in the struct itself (e.g. a `setup func()` / `setupMocks func(...)` field) or split into separate test functions.
- No `if`/`else` inside a test body to pick different assertions for different inputs. The only acceptable branch is `if err != nil` vs the success path. Cases that need different assertion shapes belong in a separate `t.Run(...)` or a separate test function.
- No loops inside a test body other than the outer `for _, tc := range tests` of a table-driven test.
- When tests share the same assertion but differ in mock/fixture setup, use a `setupMocks func(...)` field in the table struct rather than separate functions. Group by expected outcome (e.g. "returns error", "succeeds with metric=1", "no-ops") and parameterize within each group.
- If a case doesn't fit the table cleanly, write a sibling `t.Run("descriptive name", func(t *testing.T) { ... })` rather than contorting the table.
- Prefer `assert.ErrorIs` / `assert.ErrorAs` (or `errors.Is` / `errors.As`) over `assert.Contains(err.Error(), "...")`. Substring matching is acceptable only when the production code returns a freshly-constructed `fmt.Errorf` with no wrapping or sentinel and adding one purely for the test would distort the production code.

### No `ctrl.Finish()` in gomock tests

Don't write `defer ctrl.Finish()` after `gomock.NewController(t)`. Since gomock v1.5.0 the controller registers its own cleanup via `t.Cleanup`, so the explicit `Finish` is redundant. Just write `ctrl := gomock.NewController(t)` and move on.

## Architecture (for review)

- Interfaces should be defined by the consumer, not the producer. If a new interface is added next to its only implementation, flag it.
- `internal/` packages: things exposed outside `internal/` become API contracts — keep them minimal.
- Avoid `interface{}` / `any` at package boundaries when a concrete type works.
- Generics: is the type parameter pulling its weight, or would a concrete type be clearer?
