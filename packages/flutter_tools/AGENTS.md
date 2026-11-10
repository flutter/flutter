# Agent instructions for `packages/flutter_tools`

Before editing Dart code in this directory, read the "Code conventions"
and "Writing tests" sections of [README.md](README.md) and follow them.
The rules that come up most: inject dependencies instead of using
`globals`, use `testWithoutContext` with the fakes in `test/src/`, use
the wrappers in `lib/src/base/` instead of `dart:io`, and report
user-fixable failures with `throwToolExit`.

Run `flutter test test/general.shard/<file>_test.dart` for each file you
changed, then `dart analyze --fatal-infos` and `dart format` on the
modified files. `general.shard` tests must finish in under two seconds.

The Gradle plugin in `gradle/` has its own [AGENTS.md](gradle/AGENTS.md).
