Contains utilities for the Dart VM's `dart:io`.

[![pub package](https://img.shields.io/pub/v/io.svg)](https://pub.dev/packages/io)
[![ci](https://github.com/dart-lang/io/workflows/ci/badge.svg?branch=master)](https://github.com/dart-lang/io/actions?query=branch%3Amaster)

## Usage - `io.dart`

### Files

#### `isExecutable`
 
Returns whether a provided file path is considered _executable_ on the host
operating system.

### Processes

#### `ExitCode`

An `enum`-like class that contains known exit codes.

#### `ProcessManager`

A higher-level service for spawning and communicating with processes.

##### Use `spawn` to create a process with std[in|out|err] forwarded by default

```dart
Future<void> main() async {
  final manager = ProcessManager();

  // Print `dart` tool version to stdout.
  print('** Running `dart --version`');
  var spawn = await manager.spawn('dart', ['--version']);
  await spawn.exitCode;

  // Check formatting and print the result to stdout.
  print('** Running `dart format --output=none .`');
  spawn = await manager.spawn('dart', ['format', '--output=none', '.']);
  await spawn.exitCode;

  // Check if a package is ready for publishing.
  // Upon hitting a blocking stdin state, you may directly
  // output to the processes's stdin via your own, similar to how a bash or
  // shell script would spawn a process.
  print('** Running pub publish');
  spawn = await manager.spawn('dart', ['pub', 'publish', '--dry-run']);
  await spawn.exitCode;

  // Closes stdin for the entire program.
  await sharedStdIn.terminate();
}
```

#### `sharedStdIn`

A safer version of the default `stdin` stream from `dart:io` that allows a
subscriber to cancel their subscription, and then allows a _new_ subscriber to
start listening. This differs from the default behavior where only a single
listener is ever allowed in the application lifecycle:

```dart
test('should allow multiple subscribers', () async {
  final logs = <String>[];
  final asUtf8 = sharedStdIn.transform(UTF8.decoder);
  // Wait for input for the user.
  logs.add(await asUtf8.first);
  // Wait for more input for the user.
  logs.add(await asUtf8.first);
  expect(logs, ['Hello World', 'Goodbye World']);
});
```

For testing, an instance of `SharedStdIn` may be created directly.

## Usage - `ansi.dart`

```dart
import 'dart:io' as io;
import 'package:io/ansi.dart';

void main() {
  // To use one style, call the `wrap` method on one of the provided top-level
  // values.
  io.stderr.writeln(red.wrap("Bad error!"));

  // To use multiple styles, call `wrapWith`.
  print(wrapWith('** Important **', [red, styleBold, styleUnderlined]));

  // The wrap functions will simply return the provided value unchanged if
  // `ansiOutputEnabled` is false.
  //
  // You can override the value `ansiOutputEnabled` by wrapping code in
  // `overrideAnsiOutput`.
  overrideAnsiOutput(false, () {
    assert('Normal text' == green.wrap('Normal text'));
  });
}
```
