# Updating the Embedding Dependencies

## Requirements

1. Gradle. If you don't have Gradle installed, you can get it on [https://gradle.org/install/#manually](https://gradle.org/install/#manually).
2. [Depot tools](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up).

## Steps

1. Update tools/androidx/files.json. (This file includes the Maven dependencies used to build Flutter apps).
2. `cd` into this directory.
3. Run `./generate.sh`.
