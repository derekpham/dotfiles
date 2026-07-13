# Python rules

Read alongside `general.md`. This file is a starting point — add rules as they come up.

## Prefer the standard library over hand-rolled

- Comprehensions instead of manual accumulation loops.
- `min` / `max` with `key=` instead of tracking a best value by hand.
- `any` / `all` instead of a loop with a boolean flag.
- `collections.Counter` for counting; `collections.defaultdict` for grouping.
- `itertools` (`chain`, `groupby`, `product`, ...) instead of nested loops.
- `functools.cache` / `functools.lru_cache` for memoization.
- `dataclasses` for plain data holders instead of hand-written `__init__`.
- `pathlib.Path` instead of `os.path` string munging.

## Error handling

- Chain wrapped errors: `raise FooError("reading config") from err`.
- Catch the narrowest exception type that makes sense; never bare `except:`.

## Tests

- Use `@pytest.mark.parametrize("input,expected", [...])` when cases share the same arrange/act/assert shape.
- Assert on exception *type* (`pytest.raises(FooError)`), not on message substrings, unless the message is the contract.
