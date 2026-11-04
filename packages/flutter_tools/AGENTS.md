# Agent instructions for `packages/flutter_tools`

Before editing Dart code in this directory, read the **Code conventions**
and **Hermetic test checklist** sections of [README.md](README.md). That
document is the source of truth. The list below is a short subset of it.

Each of these has existing exceptions in the codebase. If a change needs
a new one, leave a comment at the site explaining why, and mention it in
the PR description so the reviewer can weigh in.

## Conventions

1. Do not add new uses of `globals.*` or the `AppContext`. Pass
   `FileSystem`, `Logger`, `ProcessManager`, `Platform`, and `Analytics`
   in through the constructor. New files must not import `globals.dart`.
2. Do not import `dart:io`. Use `package:flutter_tools/src/base/io.dart`.
3. Use `testWithoutContext` unless the code under test still reads from
   the `AppContext`. Tests in `test/general.shard` and
   `test/commands.shard/hermetic` do not touch the host file system,
   network, clock, or subprocesses.
4. Use one `MemoryFileSystem.test()` per test, shared with every object
   under test. Use `FakeProcessManager.list(...)` or `.empty()` for
   subprocesses and check `hasNoRemainingExpectations` afterwards. Use
   `BufferLogger.test()` for the logger.
5. Build paths with `fileSystem.path.join(...)`. Use `getBuildDirectory()`
   instead of a hardcoded `'build'`. Use
   `ErrorHandlingFileSystem.deleteIfExists(entity)` to delete.
6. Failures caused by the user's project or environment exit through
   `throwToolExit(...)` with a message that says what failed and what the
   user can do about it. Catch specific exception types
   (`on FileSystemException`, `on ProcessException`,
   `on FormatException`), not a bare `catch (e)`.
7. Every wait on a subprocess or device has a timeout. Do not assume a
   single device (`flutter run -d all` exists). Under `--machine`, stdout
   is JSON.

## Before finishing

Run the tests for each file you changed, for example
`flutter test test/general.shard/<file>_test.dart`. Run
`dart analyze --fatal-infos` and `dart format` on the modified files.
If you added or changed a user-facing error or warning, put the CLI
output in the PR description.

The Gradle plugin in `gradle/` has its own [AGENTS.md](gradle/AGENTS.md).
