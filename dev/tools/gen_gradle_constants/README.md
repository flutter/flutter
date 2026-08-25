# Gradle Constants Generator

This directory contains a generator that uses [Pigeon](https://pub.dev/packages/pigeon) to generate constants shared between `flutter_tools` (Dart) and the code it drives on the JVM side, such as `flutter_gradle_plugin` (Kotlin).

## Source of truth

Each set of constants is a plain Dart file, and every file generated from it is checked in. The sources, and the Java and/or Kotlin files generated from each of them, are listed in `sources` at the top of [`bin/gen_gradle_constants.dart`](bin/gen_gradle_constants.dart). Add an entry there to share a new set of constants.

Today that is:

| Dart source of truth | Generates |
| --- | --- |
| [`packages/flutter_tools/lib/src/android/gradle_constants.dart`](../../../packages/flutter_tools/lib/src/android/gradle_constants.dart) | `packages/flutter_tools/gradle/src/main/kotlin/GradleConstants.g.kt` |

## Running the tool

Run this tool from the root of the Flutter repository:

```sh
dart dev/tools/gen_gradle_constants/bin/gen_gradle_constants.dart
```

The tool prints the path of every file it writes.

The generated files are checked in so that Gradle builds do not require running a Dart code generator at build time. To make sure they stay in sync, `dev/bots/analyze.dart` regenerates them and then fails if `git diff` reports that anything changed, so regenerate and commit whenever a source of truth changes.
