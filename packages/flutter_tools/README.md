# Flutter Tools

This section of the Flutter repository contains the command line developer tools
for building Flutter applications.

## Working on Flutter Tools

Be sure to follow the instructions on [CONTRIBUTING.md](../../CONTRIBUTING.md)
to set up your development environment. Further, familiarize yourself with the
[style guide](../../docs/contributing/Style-guide-for-Flutter-repo.md),
which we follow.

### Setting up

First, ensure that the Dart SDK and other necessary artifacts are available by
invoking the Flutter Tools wrapper script. In this directory run:
```shell
$ flutter --version
```

### Running the Tool

To run Flutter Tools from source, in this directory run:
```shell
$ dart bin/flutter_tools.dart
```
followed by command-line arguments, as usual.

As a convenience for folks developing the `flutter` tool itself,
you can also use the `bin/flutter-dev` script:
```shell
# Assuming flutter/bin is on your PATH
$ flutter-dev
```

Note: `flutter-dev` is identical to `flutter`, except it does not
use a cached on-disk snapshot. In other words, it will be significantly
slower but you will not need to forget (remember?) to delete the cached
snapshot.

### Running the analyzer

To run the analyzer on Flutter Tools, in this directory run:
```shell
$ flutter analyze
```

### Changing dependencies

After editing `pubspec.yaml`, run `flutter update-packages` from the
repository root. See [Adding dependencies to the Flutter Tool](../../docs/tool/README.md#adding-dependencies-to-the-flutter-tool)
for the policy on new packages.

### Code conventions

These apply to new code. Existing code does not follow all of them. If a
change needs an exception, say why in a comment at the site.

#### Dependency injection

- Do not add new uses of `globals.*` (`globals.fs`, `globals.logger`,
  `globals.processManager`, `globals.platform`, `globals.analytics`) or
  of the Zone-based `AppContext`. Pass `FileSystem`, `Logger`,
  `ProcessManager`, `Platform`, `Analytics`, and similar dependencies in
  through the constructor or as method parameters. New files must not
  import `globals.dart`.
- Use `testWithoutContext` unless the code under test still reads from
  the `AppContext`. If a test for new code needs `overrides:`, inject the
  dependency instead.

#### Host I/O

- Some imports are banned in favor of a wrapper that can be faked in
  tests. `test/integration.shard/forbidden_imports_test.dart` enforces
  the list:

  | Instead of                 | Use                            |
  | -------------------------- | ------------------------------ |
  | `dart:io`                  | `lib/src/base/io.dart`         |
  | `dart:convert`             | `lib/src/convert.dart`         |
  | `package:path`             | `fileSystem.path`              |
  | `package:file/local.dart`  | `lib/src/base/file_system.dart` |
  | `package:http`             | `lib/src/base/io.dart`         |

  A file that has to use the raw import marks the line with
  `// flutter_ignore: dart_io_import` (or `dart_convert_import`,
  `package_path_import`, `package_http_import`).
- Build paths with `fileSystem.path.join(...)`, not string concatenation.
  Concatenated paths break on Windows.
- Use `ErrorHandlingFileSystem.deleteIfExists(entity)` instead of
  `try { entity.deleteSync(); } catch (...)`.
- Check `file.existsSync()` before reading instead of catching
  `FileSystemException`. If the file is part of the user's project,
  report a missing or unparseable file with `throwToolExit` and include
  the path.
- The build directory is configurable. Use `getBuildDirectory()` or one
  of the per-platform variants in `build_info.dart` instead of a
  hardcoded `'build'`.
- `process.kill()` sends `SIGTERM`. Use `SIGKILL` only when you have a
  reason to.

#### Errors and output

- Failures caused by the user's project, environment, or missing host
  tools exit through `throwToolExit(...)`. The message says what the tool
  was doing and what the user can do about it. Throw a `StateError` for
  internal invariant violations. See the doc comment on `throwToolExit`
  in `lib/src/base/common.dart`.
- Catch the exception types you expect (`on FileSystemException`,
  `on ProcessException`, `on FormatException`). A bare `catch (e)` also
  swallows `TypeError` and `NoSuchMethodError`.
- `throwToolExit` does not return, so code after it does not need an
  `else`.
- Use `logger.startProgress(...)` or `logger.startSpinner(...)` for
  long-running work. `startSpinner` has a `slowWarningCallback`, so a
  separate timer is not needed.
- Write output through the injected `Logger`, not `print` or
  `stdio.stdoutWrite`. Under `--machine` (used by `flutter daemon` and
  IDEs) the logger is replaced with one that turns each message into a
  JSON event, and anything written to stdout directly corrupts that
  stream.
- When a PR adds or changes an error or warning, include the CLI output
  in the PR description.

#### Devices and the build system

- `flutter run -d all` runs the same command against several devices at
  once. Do not assume a single `Device` or keep per-run state in a shared
  object.
- Code generation, asset transformation, and native packaging are
  `BuildSystem` `Target`s (`lib/src/build_system/`). `ResidentRunner` and
  commands invoke targets; they do not call into a target's internals.
  Cache expensive lookups on `Environment`, and declare every input and
  output so `Depfile` invalidation works.
- Read values from `xcodebuild` build settings (`buildSettings` on the
  build result) instead of parsing `Info.plist` for the same value.
- Before deleting a default value (a `gradle.properties` JVM flag, a
  template value, a plugin default), run `git blame` on it to find out
  why it was added.

#### Style

The [style guide](../../docs/contributing/Style-guide-for-Flutter-repo.md)
applies. In addition:

- Declare regular expressions as `static final RegExp` fields with a
  comment that says what they match and gives an example. Use several
  small regexes instead of one large one.
- Use exhaustive `switch` statements, with no `default` case, over enums
  such as `TargetPlatform` and `CpuArch` so new values fail to compile
  until handled.

### Writing tests

As with other parts of the Flutter repository, all changes in behavior
[must be tested](../../docs/contributing/Style-guide-for-Flutter-repo.md#write-test-find-bug).
Tests live under the `test/` subdirectory.

- Hermetic unit tests of tool internals go under `test/general.shard`
  and must run in significantly less than two seconds.

- Tests of tool commands go under `test/commands.shard`. Hermetic
  tests go under its `hermetic/` subdirectory. Non-hermetic tests go
  under its `permeable` sub-directory. Avoid adding tests here and
  prefer writing either a unit test or a full integration test.

- Integration tests (e.g. tests that run the tool in a subprocess) go
  under `test/integration.shard`.

- Slow web-related tests go in the `test/web.shard` directory.

In general, the tests for the code in a file called `file.dart` should
go in a file called `file_test.dart` in the subdirectory that matches
the behavior of the test.

The `dart_test.yaml` file configures the timeout for these tests to be
15 minutes. The `test.dart` script that is used in CI overrides this
to two seconds for the `test/general.shard` directory, to catch
behaviour that is unexpectedly slow.

Please avoid setting any other timeouts.

#### Hermetic test checklist

Unit tests in `general.shard` and `commands.shard/hermetic` do not
touch the host file system, clock, network, environment variables, or
subprocesses. Use the fakes in `test/src/`:

- `testWithoutContext(...)` unless the code under test still depends on
  the `AppContext`.
- One `MemoryFileSystem.test()` per test, created in `setUp` and passed
  to every object under test. With two file systems, the code writes to
  one and the assertion reads the other. `MemoryFileSystem.test()` uses a
  fake clock, so modification times are deterministic. Pass
  `style: FileSystemStyle.windows` when the test is about path handling.
- `FakeProcessManager.list(<FakeCommand>[...])` or
  `FakeProcessManager.empty()` for subprocesses. Do not write a separate
  `ProcessManager` fake. After the code under test runs, check
  `expect(processManager, hasNoRemainingExpectations)` to catch an early
  exit. Inject a `ProcessManager`, not a `ProcessUtils`;
  `testUsingContext` fails if `ProcessUtils` is overridden.
- `BufferLogger.test()` for the logger. Assert on `logger.statusText`,
  `logger.errorText`, `logger.warningText`, or `logger.traceText`.
- `FakePlatform(operatingSystem: ..., environment: ...)` for the
  platform.
- `FakeAsync` from `package:fake_async` for code that uses timers or
  `Future.delayed`, so the test does not wait in real time.
- `getInitializedFakeAnalyticsInstance(...)` for analytics when the code
  under test reports events.
- `throwsToolExit(message: ...)` to assert user-facing failures.
- `package:file_testing` matchers (`exists`, `isNot(exists)`) for file
  assertions.
- `printOnFailure` instead of `print` for diagnostic output.

Test file names end in `_test.dart`; the test runner skips other names.
`dev/bots/analyze.dart` fails if a file in a `*.shard/` directory calls
`test`, `testUsingContext`, or `testWithoutContext` and does not have
that suffix.

A test that needs the real file system, a real subprocess, or more than
two seconds belongs in `integration.shard`.

#### Using local engine builds in integration tests

The integration tests can be configured to use a specific local engine
variant by setting the `FLUTTER_LOCAL_ENGINE` and `FLUTTER_LOCAL_ENGINE_HOST`
environment variables to the name of the local engines (e.g. `android_debug_unopt`
and `host_debug_unopt`). If the local engine build requires a source path, this
can be provided by setting the `FLUTTER_LOCAL_ENGINE_SRC_PATH` environment
variable. This second variable is not necessary if the `flutter` and `engine`
checkouts are in adjacent directories.

```shell
export FLUTTER_LOCAL_ENGINE=android_debug_unopt
export FLUTTER_LOCAL_ENGINE_HOST=host_debug_unopt
flutter test test/integration.shard/some_test_case
```

### Running the tests

To run all of the unit tests:

```shell
$ flutter test test/general.shard
```

The tests in `test/integration.shard` are slower to run than the tests
in `test/general.shard`. Depending on your development computer, you
might want to limit concurrency. Generally it is easier to run these
on CI, or to manually verify the behavior you are changing instead of
running the test.

The integration tests also require the `FLUTTER_ROOT` environment
variable to be set. The full invocation to run everything might
therefore look something like:

```shell
$ export FLUTTER_ROOT=~/path/to/flutter-sdk
$ flutter test --concurrency 1
```

This may take some time (on the order of an hour). The unit tests
alone take much less time (on the order of a minute).

You can run the tests in a specific file, e.g.:

```shell
$ flutter test test/general.shard/utils_test.dart
```

### Forcing Flutter Tools Snapshot Regeneration

To force the Flutter Tools snapshot to be regenerated, delete these files:

- `flutter_tools.stamp`
- `flutter_tools.snapshot`

**On macOS/Linux:**

```bash
rm ../../bin/cache/flutter_tools.stamp ../../bin/cache/flutter_tools.snapshot
```

**On Windows:**

```bat
del ..\..\bin\cache\flutter_tools.stamp ..\..\bin\cache\flutter_tools.snapshot
```
