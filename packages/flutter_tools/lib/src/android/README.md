# Flutter Tools for Android

This section of the Flutter repository contains the command line developer tools
for building Flutter applications on Android. What follows are some notes about
updating this part of the tool.

## Updating Android dependencies
The Android dependencies that Flutter uses to run on Android
include the Android NDK and SDK versions, Gradle, the Kotlin Gradle Plugin,
and the Android Gradle Plugin (AGP). The template versions of these
dependencies can be found in [gradle_utils.dart](gradle_utils.dart).

Follow the guides below when*...

### Updating the template version of...

#### The Android SDK & NDK
All of the Android SDK/NDK versions noted in `gradle_utils.dart`
(`compileSdkVersion`, `minSdkVersion`, `targetSdkVersion`, `ndkVersion`)
versions should match the values in Flutter Gradle Plugin (`FlutterExtension`),
so updating any of these versions also requires an update in
[FlutterExtension](../../../gradle/src/main/kotlin/FlutterExtention.kt).

When updating the Android `compileSdkVersion`, `minSdkVersion`, or
`targetSdkVersion`, make sure that:
- Framework integration & benchmark tests are running with at least that SDK
version.
- Flutter tools tests that perform String checks with the current template
SDK versions are updated (you should see these fail if you do not fix them
preemptively).

Also, make sure to also update to the same version in the following places:
- The versions for error/warn in `packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt`.
- The version in the dependencies block in `packages/flutter_tools/gradle/build.gradle.kts`.
- The flutter min version in `engine/src/flutter/shell/platform/android/io/flutter/Build.java`
- The versions used when engine testing in `engine/src/flutter/shell/platform/android/test_runner/build.gradle`
- The versions used when working in engine/shell in `engine/src/flutter/shell/platform/android/build.gradle`

#### Gradle
When updating the Gradle version used in project templates
(`templateDefaultGradleVersion`), make sure that:
- Framework integration & benchmark tests are running with at least this Gradle
version.
- Flutter tools tests that perform String checks with the current template
Gradle version are updated (you should see these fail if you do not fix them
preemptively).

#### The Kotlin Gradle Plugin
When updating the Kotlin Gradle Plugin (KGP) version used in project templates
(`templateKotlinGradlePluginVersion`), make sure that the framework integration
& benchmark tests are running with at least this KGP version.

When updating the `warnKGPVersion` or `errorKGPVersion` ensure that versions used in
`dev/tools/bin/generate_gradle_lockfiles.dart` are updated if needed then regenerate
build.gradle(.kts) files.

For information about the latest version, check https://kotlinlang.org/docs/releases.html#release-details.

#### The Android Gradle Plugin (AGP)
When updating the Android Gradle Plugin (AGP) versions used in project templates
(`templateAndroidGradlePluginVersion`, `templateAndroidGradlePluginVersionForModule`),
make sure that:
- Framework integration & benchmark tests are running with at least this AGP
version.
- Flutter tools tests that perform String checks with the current template
AGP versions are updated (you should see these fail if you do not fix them
preemptively).

### A new version becomes available for...

#### Gradle
When new versions of Gradle become available, make sure to:
- Check if the maximum version of Gradle that we support
(`maxKnownAndSupportedGradleVersion`) can be updated, and if so, take the
necessary steps to ensure we are testing this version in CI.
- Check that the Java version that is one higher than we currently support
(`oneMajorVersionHigherJavaVersion`) based on current maximum supported
Gradle version is up-to-date.
- Update the `_javaGradleCompatList` that contains the Java/Gradle
compatibility information known to the tool.
- Update the test cases in [gradle_utils_test.dart](../../..test/general.shard/android/gradle_utils_test.dart) that test compatibility between Java and Gradle versions
(relevant tests should fail if you do not fix them preemptively, but should also
be marked inline).
- Update the test cases in [create_test.dart](../../../test/commands.shard/permeable/create_test.dart) that test for a warning for Java/Gradle incompatibilities as needed
(relevant tests should fail if you do not fix them preemptively).

For more information about the latest version, check https://gradle.org/releases/.

#### The Android Gradle Plugin (AGP)
When new versions of the Android Gradle Plugin become available, make sure to:
- Update the maximum version of AGP that we know of (`maxKnownAgpVersion`).
- Check if the maximum version of AGP that we support
(`maxKnownAndSupportedAgpVersion`) can be updated, and if so, take the necessary
steps to ensure that we are testing this version in CI.
- Update the `_javaAgpCompatList` that contains the Java/AGP compatibility
information known to the tool.
- Update the test cases in [gradle_utils_test.dart](../../../test/general.shard/android/gradle_utils_test.dart) that test compatibility between Java and AGP versions
(relevant tests should fail if you do not fix them preemptively, but should also
be marked inline).
- Update the test cases in [create_test.dart](../../../test/commands.shard/permeable/create_test.dart) that test for a warning for Java/AGP incompatibilities as needed
(relevant tests should fail if you do not fix them preemptively).

For information about the latest version, check https://developer.android.com/studio/releases/gradle-plugin#updating-gradle.

\* There is an ongoing effort to reduce these steps; see https://github.com/flutter/flutter/issues/134780.
