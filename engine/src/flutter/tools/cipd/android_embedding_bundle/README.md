# Updating the Embedding Dependencies

## Requirements

1. Gradle. If you don't have Gradle installed, you can get it on [https://gradle.org/install/#manually](https://gradle.org/install/#manually).
2. [Depot tools](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up).

## Steps

1. `cd` into this directory.
2. Update the dependency in build.gradle.
3. Update the dependency used in Android unit tests `shell/platform/android/test_runner/build.gradle`
4. Run `./generate.sh`.
5. Update tools/androidx/files.json. (This file includes the Maven dependencies used to build Flutter apps).
