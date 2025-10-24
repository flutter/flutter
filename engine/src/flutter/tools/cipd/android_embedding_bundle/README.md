# Updating the Embedding Dependencies

The instructions in this README explain how to create a CIPD package that
contains the build-time dependencies of the Android embedding of the Engine,
and the dependencies of the in-tree testing framework. The Android embedder is
shipped to Flutter end-users, but these build-time dependencies are not.
Therefore, the license script can skip over the destination of the CIPD package
in an Engine checkout at `src/flutter/third_party/android_embedding_dependencies`.
Even so, the CIPD package should contain a LICENSE file, and the instructions
below explain how to fetch the license information for the dependencies.

## Requirements

1. If you have a flutter/engine checkout, then you should already have
[Depot tools](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up) on your path.
1. You should have a copy of `gradle` in a flutter/engine checkout under
   `src/third_party/gradle/bin/gradle`.

## Steps

1. Update `src/flutter/tools/androidx/files.json`. (This file includes the Maven
   dependencies used to build Flutter apps).
1. `cd` into this directory: `src/flutter/tools/cipd/android_embedding_bundle`.
1. Run `gradle downloadLicenses`
1. Run `gradle updateDependencies`
1. Examine the file `./build/reports/license/license-dependency.xml`. If it
   contains licenses other than "The Apache License, Version 2.0" or something
   very similar, STOP. Ask Hixie for adivce on how to proceed.
1. Copy or move the `lib/` directory to `src/flutter/third_party/android_embedding_dependencies/`,
   overwriting its contents, and ensure the Android build still works.
1. Run `cipd create --pkg-def cipd.yaml -tag last_updated:"$version_tag"` where
   `$version_tag` is the output of `date +%Y-%m-%dT%T%z`.
1. Update the `DEPS` file entry for `android_embedding_dependencies` with the
   new tag: `last_updated:"$version_tag"`.
1. Update the GN list `embedding_dependencies_jars` in
   `src/flutter/shell/platform/android/BUILD.gn`.
1. The Gradle lockfiles will need to be updated, but they cannot be
   updated in this PR.  They will need to be updated in a follow-up
   PR.  Instead, run
   `<repo_root>/dev/tools/bin/generate_gradle_lockfiles.dart
   --no-gradle-generation --no-exclusion --ignore-locking`.  This will
   create a '.ignore-locking.md' file in all the projects that require
   Gradle locking and allow tests to pass without locking.
1. Once the initial PR is submitted, you will need to create a
   follow-up PR that updates the Gradle Lockfiles.  Run
   `<repo_root>/dev/tools/bin/generate_gradle_lockfiles.dart
   --no-gradle-generation --no-exclusion` to delete all the ignore
   files and update the Gradle Lockfiles.  Submit this PR as well.
