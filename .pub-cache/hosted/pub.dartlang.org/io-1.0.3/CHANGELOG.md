## 1.0.3

* Revert `meta` constraint to `^1.3.0`.

## 1.0.2

* Update `meta` constraint to `>=1.3.0 <3.0.0`.

## 1.0.1

* Update code examples to call the unified `dart` developer tool.

## 1.0.0

* Migrate this package to null-safety
* Require Dart >=2.12

## 0.3.5

* Require Dart >=2.1
* Remove dependency on `package:charcode`.

## 0.3.4

* Fix a number of issues affecting the package score on `pub.dev`.

## 0.3.3

* Updates for Dart 2 constants. Require at least Dart `2.0.0-dev.54`.

* Fix the type of `StartProcess` typedef to match `Process.start` from
  `dart:io`.

## 0.3.2+1

* `ansi.dart`

  * The "forScript" code paths now ignore the `ansiOutputEnabled` value. Affects
    the `escapeForScript` property on `AnsiCode` and the `wrap` and `wrapWith`
    functions when `forScript` is true.

## 0.3.2

* `ansi.dart`

  * Added `forScript` named argument to top-level `wrapWith` function.

  * `AnsiCode`

    * Added `String get escapeForScript` property.

    * Added `forScript` named argument to `wrap` function.

## 0.3.1

- Added `SharedStdIn.nextLine` (similar to `readLineSync`) and `lines`:

```dart
main() async {
  // Prints the first line entered on stdin.
  print(await sharedStdIn.nextLine());

  // Prints all remaining lines.
  await for (final line in sharedStdIn.lines) {
    print(line);
  }
}
```

- Added a `copyPath` and `copyPathSync` function, similar to `cp -R`.

- Added a dependency on `package:path`.

- Added the remaining missing arguments to `ProcessManager.spawnX` which
  forward to `Process.start`. It is now an interchangeable function for running
  a process.

## 0.3.0

- **BREAKING CHANGE**: The `arguments` argument to `ProcessManager.spawn` is
  now positional (not named) and required. This makes it more similar to the
  built-in `Process.start`, and easier to use as a drop in replacement:

```dart
main() {
  processManager.spawn('dart', ['--version']);
}
```

- Fixed a bug where processes created from `ProcessManager.spawn` could not
  have their `stdout`/`stderr` read through their respective getters (a runtime
  error was always thrown).

- Added `ProcessMangaer#spawnBackground`, which does not forward `stdin`.

- Added `ProcessManager#spawnDetached`, which does not forward any I/O.

- Added the `shellSplit()` function, which parses a list of arguments in the
  same manner as [the POSIX shell][what_is_posix_shell].

[what_is_posix_shell]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html

## 0.2.0

- Initial commit of...
   - `FutureOr<bool> String isExecutable(path)`.
   - `ExitCode`
   - `ProcessManager` and `Spawn`
   - `sharedStdIn` and `SharedStdIn`
   - `ansi.dart` library with support for formatting terminal output
