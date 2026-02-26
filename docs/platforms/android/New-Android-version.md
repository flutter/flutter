# Support a new Android API level Flutter (go/flutter-android-new-api-level)

## Objective

Provides a list of areas to consider and examples of former work for how to update Flutter to support a new version of the Android API. This generally happens every fall and spring and Flutter developers expect to build against the latest versions quickly after they are available.

### Overview

Whenever Android releases a new API version, we have to ensure Flutter apps on Android continue to successfully build on that new version. We achieve this by addressing new Android API behavioral and breaking changes when necessary and updating our infrastructure to test against the new Android API.
Addressing breaking changes will differentiate every year, while updating the Flutter on Android CI will remain similar from year to year.

Below is a guide to ensuring Flutter apps on Android work on the new API. It is recommended that you follow the directions in order. If something is blocked, move on to the next step.

Please maintain this doc to reflect the latest processes, issues, and PRs.

#### Create an Umbrella Issue for Updating to the new API

An example: updating from API 35 to API 36: <https://github.com/flutter/flutter/issues/163071>

#### Investigate new Android features

New Android features can cause breaking or behavioral changes to Flutter, and they can require a broad spectrum of work. The Flutter Android team should investigate these new Android API features and determine which are no-ops and which require work. We are generally aware of breaking changes and schedule work ahead of time.

#### Bump compile and target SDK versions in samples

Samples, especially add to app samples, represent apps that mirror the first types of users we see adopt new Android APIs.

Example PR: https://github.com/flutter/samples/pull/2368

---

### Update Robolectric

Robolectric is a dependency that allows us to write unit tests that run on a local development machine against the Android API surface without being on an Android device.

1. Check online for the Robolectric release notes. It is possible that a Robolectric version supporting the new Android API has not been released yet. You are blocked until that new version is released.

2. Find all usages of Robolectric in `flutter/flutter` (including the engine) and `flutter/packages` and update them.

- Example: <https://github.com/flutter/flutter/issues/177674>.

---

### Update CI

To ensure Flutter is properly tested against the new Android API, we must update the Flutter CI accordingly.

#### Update local tooling/devices to the new API Version

First, find the new Android API release notes online and follow the instructions outlined in the notes to upgrade the following tooling to the new Android API version:

- Update Android Studio
- Add at least one emulator on the new Android API (for testing)
- Upgrade at least one physical device to the new Android API (for testing)

#### Upload new SDK and other dependencies to [CIPD](https://chrome-infra-packages.appspot.com/p/flutter/android)

Flutter now includes a script to download, package, and upload the Android SDK to CIPD. These CIPD packages are then used as dependencies by the Flutter engine and recipes (go/flutter-luci-recipes) so that there is a stable archived version of the Android SDK to depend on. The script is located in the flutter/flutter repo under `engine/src/flutter/tools/android_sdk/create_cipd_packages.sh`.

> Before uploading to CIPD, please double-check that the Android SDK configurations in the text file are correct.
> Be cautious when uploading new packages to CIPD because it is difficult to undo. If you need to remove an uploaded CIPD tag, follow the documentation [here](http://go/flutter-luci-playbook#remove-duplicated-cipd-tags).

Please do not manually upload a new Android API version to CIPD. Instead, follow these steps:

1. To upload packages to CIPD (either with the script or manually), the  `flutter-cipd-writers` role is required in order to complete this operation. Googlers can apply for access [here](https://grants.corp.google.com/#/grants?request=8h%2Fflutter-cipd-writers). Once this role is granted, `cipd auth-login` must be run in order for cipd to update the user's available roles.

2. Reference the new Android API release notes for new SDK Tooling minimum configuration versions (NDK, build tools, CMake, etc.).

3. To update the Android SDK tooling configurations to the versions you want, edit [`tools/android-sdk/packages.txt`](https://github.com/flutter/flutter/blob/main/engine/src/flutter/tools/android_sdk/packages.txt) . The format for each line in packages.txt is `<package_name>:<subdirectory_to_upload>`. Typically, each `<package_name>` should be updated to the latest available version which can be found with the `sdkmanager --list --include_obsolete`. `sdkmanager` can be found in your `commandline-tools` package of the android sdk.

4. Execute this script [here](https://github.com/flutter/flutter/blob/main/engine/src/flutter/tools/android_sdk/create_cipd_packages.sh) by running the following command: `cd tools/android_sdk && ./create_cipd_packages.sh <your-tag-version> <your-local-sdk-path>`

5. Make a PR with the updated SDK tooling configurations. Although you do not need to merge a PR with the tooling script changes to successfully upload to CIPD, you should still make a PR so we have a paper trail of the SDK configuration changes made to CIPD (assuming only this script was used to upload Android SDKs to CIPD). That way we do not have to download previous CIPD versions or revisions to check the history of configurations.

Note: It is no longer recommended to upload CIPD Android SDK packages manually, but if it must be done, run the following commands to zip and upload each package to CIPD:

`$ cipd create -in <your-android-dir>/Android/sdk/<some_package> -name flutter/android/sdk/<some_package> -tag version:<new-version-tag>`

Typically, `<your-android-dir>` is in your home directory under `~/Library/Android`. The `<new-version-tag>` is what you will use to specify the new package you uploaded in the `DEPS` file.

- Example PR: <https://github.com/flutter/flutter/pull/175365>.
- Example PR: <https://github.com/flutter/flutter/pull/179963>.

---

### Update SDK and Dependency Versioning Support

New versions of Android have new dependency version minimums. We must update the Flutter apps we test against. These are existing Flutter apps that test against realistic use cases of Flutter on Android, such as Flutter plugin examples and Flutter integration tests. We must also update the Flutter templates' dependency versions, which will affect newly created Flutter on Android apps. For best practices, we should first update all Flutter Android apps we test against then the `ci.yaml`, as these steps won’t directly affect users. After that, we will update the Flutter templates, which will directly affect users.

#### Update `android_sdk` in `ci.yaml`

Update the `android_sdk` version in `flutter/flutter` and `flutter/packages` ci.yaml to test against the new android sdk. If Flutter must test against a new version of java, you must also update the ci.yaml.

- Example PR where relevant changes are only in the `ci.yaml` file: <https://github.com/flutter/flutter/pull/166464>
- Example PR where the relevant change is only to the `android_sdk` version in `ci.yaml` file: <https://github.com/flutter/packages/pull/9414>

#### Update Flutter Android Packages Defaults
- Set examples to build with the new API.
- Update `create_all_packages` to use new api as compile sdk [source](https://github.com/flutter/packages/blob/3515abab07d0bb2441277f43c2411c9b5e4ecf94/script/tool/lib/src/create_all_packages_app_command.dart#L245-L249).

- Example PR: <https://github.com/flutter/packages/pull/9293>.

#### Update Flutter Android Engine Defaults

When new Android versions become available, the following steps should be taken in order to fully support the new API version in the Flutter engine. These steps only change the engine to build against and target the new API and do not guarantee that everything works with the changes in the new Android API.

Modify the following files as described:
- `DEPS`: Change the version parameter under `flutter/android/sdk/all/${{platform}}` to the newly uploaded CIPD version tag, e.g. `'version': 'version:30r2'`
- `DEPS`: If necessary, change the version parameter above `flutter/gradle` to a newer gradle version tag, e.g. `'version': 'version:8.11.1'`
- `tools/javadoc/gen_javadoc.py`: Bump the reference to `android-XX` in `classpath` to the latest version.
- `tools/cipd/android_embedding_bundle/build.gradle`: Bump `compileSdkVersion XX` to the latest version.
- `shell/platform/android/test_runner/build.gradle`: Bump `compileSdkVersion XX` to the latest version.
- `shell/platform/android/AndroidManifest.xml`: Bump `android:targetSdkVersion=XX` to the latest version.
- `testing/android/native_activity/native_activity.gni`: Bump the reference to `build-tools/XX` in `android_buildtools` to the latest `build-tools` version and the reference to `android-XX` in `android_jar` to the latest version.

This list may become outdated, so be sure to change any references to the old SDK version to the latest version in `build.gradle` files across the repo.

- Example PR: <https://github.com/flutter/flutter/pull/166796>.

#### Update all existing Flutter on Android apps in our repos

1. Reference the new Android API release notes to see the required dependency version minimums.

2. Update the build dependencies accordingly (new API and dependencies).

* `flutter/flutter` example PR: <https://github.com/flutter/flutter/pull/176858>.
* `flutter/packages` example PR: <https://github.com/flutter/packages/pull/9241>.

#### Update Versions in the Flutter Android Template

1. Reference the new Android API release notes to see the required dependency version minimums.

2. Update the Flutter templates to use the new Android API and new dependency versioning minimums and create a PR. Do not update the template `targetSdk` in this change because additional infra changes may be necessary.

3. Once the previous change passes post submit checks and is not flaky for 100 commits, please create a new PR to update the `targetSdk`.

Once you update the templates, the new versions should show up in a newly created Flutter app (even with nothing merged). As a sanity check, you should verify that a Flutter app successfully builds to Android with these new updates.

Before merging, verify that Flutter apps can build successfully with the new minimums:

1. `flutter create <new-app-name>`
2. Run `flutter analyze --suggestions` (to check dependency versioning compatibility)
3. Run `flutter build apk` (to ensure the app builds successfully)

- Example PR: <https://github.com/flutter/flutter/pull/166464>

---

### Add New Physical Device For Firebase Test Lab

Firebase Test Lab emulators and physical devices require support from the Firebase team.

To check if a physical device with the new API version is available, run the command `gcloud firebase test android models list` (see [documentation](https://firebase.google.com/docs/test-lab/Android/available-testing-devices)) to view available devices.

We test against a physical device only in the framework CI.
- Example PR: <https://github.com/flutter/flutter/pull/136736>.

### Update AVD

Flutter managed emulators (engine) require a new AVD image to one that supports the new API.

Update CI to test against the new Android API AVD for framework, engine, and packages. Be sure to use the same AVD for framework, engine, and packages. Steps to update CI:

1. Locate the latest uploaded AVD [here](https://chrome-infra-packages.appspot.com/p/chromium/tools/android/avd/linux-amd64/) and verify that it has the desired generic\_android\<API\#\>.textpb for the new API version you are supporting.

2. Determine the instance identifier.

3. Update the emulator configurations. For example, update the .ci.yaml entry within framework like so:
```yaml
  linux_android_emu:
    properties:
      contexts: >-
        [
          "android_virtual_device"
        ]
      dependencies: >-
        [
          ...
          {"dependency": "android_virtual_device", "version": "android_<API#>_google_apis_x64.textpb"},
          {"dependency": "avd_cipd_version", "version": "build_id:<Instance ID>"},
        ]
      ...
```

- Example Framework PR: <https://github.com/flutter/flutter/pull/165926>.
- Example Engine PR: <https://github.com/flutter/flutter/pull/169124>.

We use the AVD provided by Chromium. It is possible the new AVD may fail against our tests in post-submit. In that case, we have to work with Chromium to better understand the issue. They will likely release a revision with a fix. To dogfood this AVD, you create a new testing platform configuration and add the failing test to bringup.

Example PR: <https://github.com/flutter/flutter/pull/177854/files>

### Upgrade Physical Devices in Lab to New API

We maintain a suite of physical Android devices to test Flutter apps shipping to Android. To update these devices to the new Android API, we must submit tickets to our lab manager. Some devices can be immediately updated to the new Android API (or OS’s that support the new Android API), while others cannot. If it is not possible to immediately update the device, monitor the device release notes and submit tickets to our lab manager once updating the device to the new API is possible.

**DO NOT** submit tickets to update all devices at the same time. We want to ensure there are enough devices remaining per pool to handle testing. Follow the directions to update physical devices in this internal doc [here](https://docs.google.com/document/d/1s_pulTbL3x24WHyX7bPZF7P7slfQg1Lx1LtBpUnqSug/edit?resourcekey=0-XoUQfo5So1pNuaUAHt9BbQ&tab=t.0).

- Example issues for lab manager: <https://github.com/flutter/flutter/issues/171394>.

It is possible that some devices can never be updated to the new Android API because they have reached their end-of-life where no future Android APIs will be supported. In this case, you must choose replacement devices with comparable specs.

- Example: [Mokey Replacement Doc \[Internal\]](https://docs.google.com/document/d/1Ak6h7DxZnTa_BJLy3niz-OQ3HQM-06mjC0KRPVQu9zA/edit?tab=t.0#heading=h.ixbhugneao4x)

---

### Update Java Version in CI (Only for Java LTS Release)

Every few years Java releases a new Java LTS (long-term support) version, which typically
becomes the industry standard for a few years. As users adopt the new Java LTS version, either
directly or as part of the latest Android SDK, we want to update our CI to test against the new Java version
to identify and address potential compatibility issues.

Upload the new Java Version package to CIPD following the instructions [here](/docs/platforms/android/Uploading-New-Java-Version-to-CIPD.md).

Update the usages of the current Java version to the new Java version in CI.

- Example PR: <https://github.com/flutter/flutter/pull/165210>.

### Update documentation

Update documentation page to indicate the new API is tested
https://docs.flutter.dev/reference/supported-platforms.

### Test “Integration Test” package

Integration test is a package shipped in the Flutter tool for running integration tests on Flutter apps. Ensure that the integration test package has an example that targets the new API level on the most recent published stable version of the Flutter tool.

### Related documents

[Emulators for Flutter Android Testing (PUBLICLY SHARED)](https://docs.google.com/document/d/10wYUcLcSTF4Epg2EUGoBqOkkOe4zxKHvYKjXFZAOgGs/edit?resourcekey=0-pltjPvEtVezXDADMbUwFHQ)
