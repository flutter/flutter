# Gradle Constants Generator

This directory contains a generator that uses [Pigeon](https://pub.dev/packages/pigeon) to generate shared Gradle build property constants and target/ABI constants from `flutter_tools` (Dart) into `flutter_gradle_plugin` (Kotlin).

## Source of truth

The source of truth for the constants is defined in [`packages/flutter_tools/lib/src/android/gradle_constants.dart`](../../../packages/flutter_tools/lib/src/android/gradle_constants.dart). This is a standard Dart file containing the shared constants.

## Running the tool

Run this tool from the root of the Flutter repository:

```sh
dart dev/tools/gen_gradle_constants/bin/gen_gradle_constants.dart
```

This generates:
* `packages/flutter_tools/gradle/src/main/kotlin/GradleConstants.g.kt` (Kotlin)

The generated Kotlin file should be checked in so that Gradle builds do not require running a Dart code generator at build time.
