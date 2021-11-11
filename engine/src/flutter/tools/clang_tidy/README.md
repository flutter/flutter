# clang_tidy

This is a Dart program/library that runs clang_tidy over modified files in the Flutter engine repo.

By default the linter runs on the repo files changed contained in `src/out/host_debug/compile_commands.json` command.
To check files other than in `host_debug` use `--target-variant android_debug_unopt`,
`--target-variant ios_debug_sim_unopt`, etc.

Alternatively, use `--compile-commands` to specify a path to a `compile_commands.json` file.

```
$ bin/main.dart --target-variant <engine-variant>
$ bin/main.dart --compile-commands <compile_commands.json-path>
$ bin/main.dart --help
```
