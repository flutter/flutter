When new Android versions become available, the following steps should be taken in order to fully support the new API version in the Flutter engine. These steps only change the engine to build against and target the new API and do not guarantee that everything works with the changes in the new Android API.
## Update the [Engine](https://github.com/flutter/flutter/tree/master/engine):

### Update the compile and target SDK versions we use

Modify the following files as described:
* `DEPS`: Change the version parameter under `flutter/android/sdk/all/${{platform}}` to the newly uploaded CIPD version tag, e.g. `'version': 'version:30r2'`
* `DEPS`: If necessary, change the version parameter above `flutter/gradle` to a newer gradle version tag, e.g. `'version': 'version:8.11.1'`
* `tools/javadoc/gen_javadoc.py`: Bump the reference to `android-XX` in `classpath` to the latest version.
* `tools/cipd/android_embedding_bundle/build.gradle`: Bump `compileSdkVersion XX` to the latest version.
* `shell/platform/android/test_runner/build.gradle`: Bump `compileSdkVersion XX` to the latest version.
* `shell/platform/android/AndroidManifest.xml`: Bump `android:targetSdkVersion=XX` to the latest version.
* `testing/android/native_activity/native_activity.gni`: Bump the reference to `build-tools/XX` in `android_buildtools` to the latest **build-tools** version and the reference to `android-XX` in `android_jar` to the latest version.

This list may become outdated, so be sure to change any references to the old SDK version to the latest version in `build.gradle` files across the repo.
