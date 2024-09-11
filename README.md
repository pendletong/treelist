# treelist

Treelist implementation from glib (https://github.com/pendletong/glib) as a standalone module
This implements an AVL tree to allow for a very fast list manipulation which performs best for larger lists
where items are inserted rather than prepended

- Benchmarks show around 3-6 times faster than a non-prepend addition to a standard gleam list with 1000 items
- Arbitrary removal from a treelist becomes around 6 times faster than a standard list around 1000 items and this increases to about 40 times faster at 10000 items
- Replacing arbitrary elements in a treelist is about 1.4 times faster with 100 items up to over 100 times faster for 10000 items.
- Memory usage of a treelist appears to be reasonable and if the list is being constantly modified/added to/removed arbitrarily
then usage seems to be lighter than for standard lists.

If the ability to access specific elements in a large array or removal of said elements is absolutely necessary and
this needs to work in both erlang and javascript targets then this is a good option.

[![Package Version](https://img.shields.io/hexpm/v/treelist)](https://hex.pm/packages/treelist)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/treelist/)

```sh
gleam add treelist@1
```
```gleam
import treelist

pub fn main() {
  let list = treelist.new()
  let assert Ok(new_list) = treelist.add(list, "Test")
  treelist.get(new_list, 0)
  // -> Ok("Test")
}
```

Further documentation can be found at <https://hexdocs.pm/treelist>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
