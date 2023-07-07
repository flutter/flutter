# Changelog

## 0.7.2

- Upgrade to `package:lints` 2.0.
- Populate the pubspec `repository` field.

## 0.7.1

- Make `CallGraphNode.dominator` nullable.

## 0.7.0

- Migrate to null-safety.

## 0.6.0

- Update to latest args, path, meta dependency.

## 0.5.6
- Fix for flutter/flutter#76313 causing issues with profiles containing
WSRs serialized as smi-s instead of actual WSR objects.=

## 0.5.5
- Add `deps-display-depth` (`-d`) flag for `summary` command to make the display
depth of outputted dependency trees configurable.
- Rename `deps-collapse-depth` (formerly `-d`) flag for `summary` command to
`deps-start-depth` (now `-s`).
- Add `generateCallGraphWithDominators` method that generates a `CallGraph`
object from precompiler trace.

## 0.5.4
- Fix bug causing name clash for Type class.

## 0.5.3
- Add `compareProgramInfo` that takes in two program info objects and outputs
a `Map` object containing the diff data.

## 0.5.2
- Add support for package paths that look like `package:foo.bar.baz/src/foobar.dart`
- Move `commands` back to lib.

## 0.5.0+1
- Fix broken package by moving non-executable file out of bin/ directory.

## 0.5.0
- Remove `dart:io` dependency from package `lib`, and move `commands` to `bin`.
- Replace `loadProgramInfo` util method with `loadProgramInfoFromJson`, which
expects an `Object` parameter instead of a `File` parameter.
- `buildComparisonTreemap` now expects two `Object` parameters for `oldJson` and
`newJson` instead of two `File` parameters.
- `compare` command now prints difference breakdown by node type when this
information is available.

## 0.4.0

- Add `buildComparisonTreemap` for constructing treemap representing the diff
between two size profiles.
- Implemented support for extracting call graph information from the AOT
compiler trace (`--trace-precompiler-to` flag), see `precompiler_trace.dart`.
- New command `explain dynamic-calls` which estimates the impact of different
dynamic calls on the resulting AOT snapshot size using information from the
size dump (e.g. V8 snapshot profile) and AOT compiler trace.
- `summary` command can now use information from the AOT compiler trace to
group packages/libraries together with their dependencies to given more precise
estimate of how much a specific package/library brings into the snapshot.

## 0.3.0

- Extract treemap construction code into a separate library, to make it
reusable.
- Add ability to collapse leaf nodes in a treemap created from V8 snapshot
profile. This behavior is programmatically controlled by `TreemapFormat format`
parameter and from CLI via `--format` flag. The following options are available
    - `collapsed` essentially renders `ProgramInfo` as a treemap, individual
    snapshot nodes are ignored.
    - `simplified` same as `collapsed`, but also folds size information from
    nested functions into outermost function (e.g. top level function or a
    method) producing easy to consume output.
    - `data-and-code` collapses snapshot nodes based on whether they represent
    data or executable code.
    - `object-type` (default) collapses snapshot nodes based on their type only.
- When computing `ProgramInfo` from a V8 snapshot profile no longer create
`ProgramInfoNode` for `Code` nodes which are owned by a function - instead
directly attribute the `Code` node itself and all retained nodes into
`ProgramInfoNode` for the function itself. For stubs (including allocation
stubs) create an artificial `functionNode` instead of using `NodeType.other`.
The only remaining use of `NodeType.other` is for fields.

## 0.2.0

- Update CLI help message to avoid referring to a snapshot created by pub as the
name of the script.
- Fix owner computation code for V8 profiles: the size of a snapshot node
which corresponds to a `ProgramInfoNode` should be attributed to that
`ProgramInfoNode` and not to its parent. For example `Function` node corresponds
to `ProgramInfoNode` of type `functionNode`, previously the size of `Function`
node would be attributed to the parent of this `ProgramInfoNode`, but it
should be attributed to the node itself.
- Update `README.md` to include more information on how to pass flags to
Dart AOT compiler.
- Add `ProgramInfoNode.size` documentation to clarify the meaning of the member.

## 0.1.0

- Initial release
