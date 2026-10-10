# gn_to_bazel

Converts the engine's `BUILD.gn` files to `BUILD.bazel` files, for the
GN-to-Bazel migration. The GN files stay the source of truth while the two
builds coexist; the Bazel files are generated from them and checked in.

## Usage

```sh
cd engine/src/flutter/tools/gn_to_bazel
dart bin/gn_to_bazel.dart            # regenerate every file in the manifest
dart bin/gn_to_bazel.dart --check    # verify them (the presubmit)
dart bin/gn_to_bazel.dart ../../fml/BUILD.gn   # one file
dart test
```

The manifest (`lib/src/manifest.dart`) lists the GN files whose
`BUILD.bazel` is generated, each with the targets to skip (those whose
dependencies have no Bazel build yet, with the reason) and, where the GN file
has no way to say something Bazel needs, Starlark to append. Adding a file to
the migration means adding it there; the skip lists shrink as it proceeds.

Each input is written next to it as `BUILD.bazel` (or under `--out-dir`, laid
out by GN package). `--check` compares with the existing file instead and
fails on a difference. The output is piped through `buildifier` when one is
on `PATH` (or named by `--buildifier`); the emitter already writes
buildifier's format, so the result is the same either way.

By default the converter assumes the Linux x64 host build: GN conditions on
`is_linux`, `is_win`, `enable_backtrace` and so on are decided the way GN
would decide them for that build, and the items they guard are emitted with
the condition as a comment. `--assume name=value` replaces the defaults;
`--assume=none` keeps every condition and renders it as a `select()`, which
needs a `config_setting` for each variable involved (see `conditionSettings`).

## How it works

GN build files are programs; Bazel wants data. The converter has three layers:

1. `gn_ast.dart` -- the syntax tree, read from `gn format --dump-tree=json`.
   GN's own parser is the only parser.
2. `gn_eval.dart` -- a symbolic evaluator. Each assignment is recorded with
   the condition under which it happens, so `if (is_linux) { sources += [...] }`
   becomes "under `is_linux`, append these to `sources`". Assumptions fix
   variables and prune dead branches.
3. `starlark_emitter.dart` -- the mapping from GN targets to Bazel rules:
   `source_set`/`static_library` to `cc_library` (with headers in `hdrs`,
   `deps` as `implementation_deps`, `public_deps` as `deps`; a `source_set`
   is `alwayslink`, since GN links all of its objects), test executables to
   `cc_test`, `config` to a header-only `cc_library` carrying the defines,
   include directories and link flags that dependents list in `deps`, known
   `.gni` templates to the matching Bazel macros.

`bazel_mapping.dart` holds the converter's knowledge of the engine: label
translations for synced dependencies (`//flutter/third_party/icu` is `@icu`),
what each GN config contributes, which `config_setting` stands for which GN
predicate, and the test sizes. Extending the converter's coverage means adding
to these tables.

### Strict mode

The converter never guesses. Anything outside the subset it understands --
`foreach`, `exec_script`, template definitions, string expansions, a label
with no Bazel home, a config with no mapping, a condition with no
`config_setting` -- is an error that names the GN file and line. The fix is
either to teach the converter the construct or to simplify the GN file;
GN build files that are plain data convert cleanly.

### Comments

Comments travel with what they document: a comment above a target precedes
the rule, a comment above a `=` precedes the attribute, a comment above a
`+=` or above a list item stays with the item. Comment blocks that stand on
their own (separated by a blank line) are left behind.
