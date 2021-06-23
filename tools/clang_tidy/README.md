# clang_tidy

This is a Dart program/library that runs clang_tidy over modified files. It
takes two mandatory arguments that point at a compile_commands.json command
and the root of the Flutter engine repo:

```
$ bin/main.dart --compile-commands <compile_commands.json-path> --repo <path-to-repo>
```
