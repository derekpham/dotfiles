# TypeScript / JavaScript rules

Read alongside `general.md`. This file is a starting point — add rules as they come up.

## Prefer the standard library over hand-rolled

- `Array.prototype.{includes, find, some, every, flatMap}` instead of manual loops.
- `Object.{entries, fromEntries, groupBy}` instead of building objects by hand.
- `Map` / `Set` instead of using plain objects as keyed collections.
- `structuredClone(x)` instead of `JSON.parse(JSON.stringify(x))`.

## Types

- Avoid `any` at module boundaries; prefer a concrete type or `unknown` with narrowing.
- Prefer discriminated unions over optional-field grab-bags when modeling variants.

## Tests

- Use `describe.each([...])` / `it.each([...])` when cases share the same arrange/act/assert shape.
- Assert on error type / instance, not on message substrings, unless the message is the contract.
