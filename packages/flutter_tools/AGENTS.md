# Agent instructions for `packages/flutter_tools`

Before editing Dart code in this directory, read the "Code conventions"
and "Writing tests" sections of [README.md](README.md) and follow them.
The rules that come up most: inject dependencies explicitly instead of using
ambient globals or Zone lookups, use `test` with fakes from `test/src/`, use
the wrappers in `lib/src/base/` instead of `dart:io`, and report user-fixable
failures with `throwToolExit`.

Run `flutter test test/general.shard/<file>_test.dart` for each file you
changed, then `dart analyze --fatal-infos` and `dart format` on the
modified files. `general.shard` tests must finish in under two seconds.

The Gradle plugin in `gradle/` has its own [AGENTS.md](gradle/AGENTS.md).
