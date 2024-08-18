Support a new android API level flutter
go/flutter-android-new-api-level

## Objective
Provide a list of areas to consider and examples of former work for how to update flutter to support a new version of the android API. This happens every fall and flutter developers expect to build against the latest versions quickly after they are available.
### Overview
#### New Android features
New android features can require a broad spectrum of work. Some will require nothing from flutter. Some will require a lot of work, such as the support for “back preview”. The android team generally needs to be aware and schedule work ahead of time.
#### Update Gradle/AGP support
Sometimes newer versions of gradle are required to build without warning against a new version of android api. The warning looks like
```
WARNING:We recommend using a newer Android Gradle plugin to use compileSdkPreview = "somenamedversion"
This Android Gradle plugin (X.X.X) was tested up to compileSdk = XX
```
Bump the gradle version used in the engine.


#### Update Robolectric
Robolectric is a dependency that allows us to write unit tests that run on a local development machine against the android api surface without being on an android device.
Update what version of Robolectric we use in framework, engine and packages.
Example packages: https://github.com/flutter/packages/pull/4018
Example engine: https://github.com/flutter/engine/pull/42965


#### Update CI

Update emulator and/or physical device testing to use the new android api version for framework, engine and packages.
Firebase test lab emulators and physical devices need support from the firebase team
Run command `gcloud firebase test android models list` [documentation](https://firebase.google.com/docs/test-lab/android/available-testing-devices) to see available devices.
Flutter managed Emulators (engine) require a new AVD image to one that supports the new api: https://flutter-review.googlesource.com/c/recipes/+/45049
Example Framework: https://flutter-review.googlesource.com/c/recipes/+/45048
Example Engine: https://github.com/flutter/engine/pull/42492
Packages
Modify https://github.com/flutter/packages/blob/main/.cirrus.yml “firebase_test_lab_script”
Specifically the value for “--device” `./script/tool_runner.sh firebase-test-lab --device model=redfin,version=30 --exclude=script/configs/exclude_integration_android.yaml`
https://github.com/flutter/packages/pull/4430
#### Update documentation
Update documentation page to indicate the new api is tested
https://docs.flutter.dev/reference/supported-platforms
#### Modify defaults
In flutter/flutter:
Update default compile sdk version and target sdk version to the new api value
[Code here](../../../packages/flutter_tools/gradle/src/main/groovy/flutter.groovy)
Follow comments in that file to update other locations that are assumed to be the same.
Example bumping min sdk which is similar but different: https://github.com/flutter/flutter/pull/125515
In flutter/buildroot:
Upload new android sdk version to CIPD (steps at end of document)
Update default android sdk version
https://github.com/flutter/buildroot/blob/7984a08044b94bfb4c466ac881c6b56fdfe9148b/build/config/android/config.gni#L19
In flutter/engine:
Update android SDK in DEPS file
https://github.com/flutter/engine/blob/9289cb6a36aa86990e3ffe0f20324dafa38e7c11/DEPS#L731
Update buildroot version in DEPS file to consume the changes in the flutter/buildroot steps above
https://github.com/flutter/engine/blob/9289cb6a36aa86990e3ffe0f20324dafa38e7c11/DEPS#L260
In flutter/packages
Set examples to build with the new api.
#### Test “Integration Test” package
Integration test is a package shipped in the flutter tool for running integration tests on flutter apps. Ensure that the integration test package has an example that targets the new api level on the most recent published stable version of the flutter tool.

#### Related documents
[Emulators for Flutter Android Testing (PUBLICLY SHARED)](https://docs.google.com/document/d/10wYUcLcSTF4Epg2EUGoBqOkkOe4zxKHvYKjXFZAOgGs/edit?resourcekey=0-pltjPvEtVezXDADMbUwFHQ)

### Additional notes
#### Upload new SDK version to CIPD and consume in buildroot

Make a fork of the [buildroot](https://github.com/flutter/buildroot) if you haven’t yet.
Get CIPD temporary write access, if you don’t have it:
Make a github issue describing that there is a new android release that needs to be uploaded to CIPD
 Go to [go/flutter-luci-cipd#requesting-writeread-access-to-cipd-packages](http://goto.google.com/flutter-luci-cipd#requesting-writeread-access-to-cipd-packages) and click request access on the hyperlinked page
Fill out the justification with b/12345 - <your GitHub issue> (the form requires a buganizer link, and the addition of b/12345 satisfies this).
Reach out to someone on the infra team to get your request approved
Run the [create_cipd_packages.sh script](https://github.com/flutter/engine/blob/a2adaa39a2c35d1ab23394d550c9a7e50fe41fe9/tools/android_sdk/create_cipd_packages.sh) with your desired version tag (note that there is a .ci.yaml validation step that requires this version tag to be a combination of lowercase letters and numbers). The script pulls the version that will be uploaded from the packages.txt file in the same subdirectory.
The remaining steps are to consume the changes in the buildroot, and then consume those buildroot changes in the engine.