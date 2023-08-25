# Updating gradle version used in engine repo

The instructions in this README explain how to create a CIPD package that
contains the gradle build-time dependency of the Android embedding of the Engine.
The Android embedder is shipped to Flutter end-users, but gradle is not.

## Requirements

1. If you have a flutter/engine checkout, then you should already have
[Depot tools](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up) on your path.
1. Ensure you have write access for cipd. go/flutter-luci-cipd
1. Download the new version of gradle then verify the checksum,
and unzip into a local directory.

## Update CIPD Steps
These steps use gradle version 7.5.1 as an example.

1. Unzip gradle into a folder `unzip gradle-7.5.1-all.zip`
1. Authenticate with cipd `cipd auth-login`
1. Run `cipd create -in gradle-7.5.1 -install-mode copy -tag version:7.5.1 -name flutter/gradle`
1. Update `engine/src/flutter/DEPS` gradle entry to contain the tag from the command above.
1. Run `gclient sync` to verify that dependency can be fetched.

## Useful links
* CIPD gradle https://chrome-infra-packages.appspot.com/p/flutter/gradle/+/
* Gradle Releases https://gradle.org/releases/