# Kotoba Tree-sitter

Kotoba bindings for the host-facing Tree-sitter **node / tree / cursor**
shape. They compile with [kotoba](https://github.com/kotoba-lang/kotoba)
v0.7.2 to Wasm.

## What this is

Kotoba cannot FFI `libtree-sitter`. This tree does **not** rewrite the C
parser and does **not** pretend to parse source. v1 is:

1. A host-facing API (`node-*`, `tree-*`, `cursor-*`) whose documents match
   the C/Rust/Web accessors (`type`, `named`, byte/point span, children,
   field names, S-expression).
2. An EDN encoding of [static node types](../../docs/src/using-parsers/6-static-node-types.md)
   (`fixtures/node-types.edn`).
3. A walk over a **vendored** CST fixture (`fixtures/tree.edn`) for
   `x = 1`.

A host that *can* call the C library may inject a tree document with the
same keys. `host-can-parse?` returns `0` until that capability exists.

## Build

Requires kotoba **v0.7.2**.

```sh
kotoba compile lib/binding_kotoba/src/tree_sitter.kotoba --target wasm --output tree_sitter.wasm --json
```

Accept `kotoba.cli/ok?` true and `kotoba.cli/code` `emitted`. The artifact
must start with Wasm magic `\0asm`.

```sh
lib/binding_kotoba/scripts/ci.sh
```

`require` is not admitted, so examples and tests are bundled onto the
single compilation unit.

## Fixture

Source: `x = 1`

```
(source_file (assignment (identifier) "=" (number)))
```

| id | type | named | field | span |
|----|------|-------|-------|------|
| 0 | source_file | yes | | 0–5 |
| 1 | assignment | yes | | 0–5 |
| 2 | identifier | yes | left | 0–1 |
| 3 | `=` | no | | 2–3 |
| 4 | number | yes | right | 4–5 |

Walk with `cursor-goto-first-child` / `cursor-goto-next-sibling` /
`cursor-goto-parent`, or with `node-child` / `node-child-by-field-name`.
