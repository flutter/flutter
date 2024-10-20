# Flutter postmortem: Widespread Gradle failures on Flutter v1.12.13+hotfix.5

Status: final<br>
Owners: amirh@

## Summary

Description: Many users reported Gradle build failure after upgrading to Flutter v1.12.13+hotfix.5 <br>
Component: plugins<br>
Date: 2019-12-11<br>
Duration: 19 hours<br>
User impact: Users of the following plugins: url_launcher, google_sign_in, video_player, firebase_auth, firebase_core, shared_preferences who are using Android Studio couldn’t build their applications.

## Timeline (all times in PST/PDT)

### 2019-09-01
stuartmorgan@ notices that Flutter applications that are using non-Android plugins are failing to build for Android (same for iOS) and files https://github.com/flutter/flutter/issues/39657. The root cause is that the Flutter gradle plugin assumes that all plugins include an Android implementation and tries to build it.

### 2019-09-16
stuargmorgan@ prototypes [a fix](https://github.com/flutter/flutter/compare/main...stuartmorgan:wip-platform-plugin-files?expand=1). That fix requires migration of existing plugins.

### 2019-09-18
As a temporary workaround for the issue above (Android only), amirh@ lands https://github.com/flutter/flutter/pull/40640 which makes `flutter.gradle` skip packages that do not have an `android/build.gradle` file, this workaround lives in the Flutter SDK and does not require plugin migration.

The change lands with a test that:
 1. Creates a new ios-only flutter plugin named flutter_plugin_test
 1. Deletes the android/ folder
 1. Creates a new flutter app which depends on flutter_plugin_test
 1. Builds an apk for that app

In the following months work starts on federated web and mac implementations of `flutter/plugins` and `FirebaseExtended/flutterfire` plugins. With #40640 landed, these implementations all land without an `android/` folder.

### 2019-11-25
blasten@ lands https://github.com/flutter/flutter/pull/45379 which reworks the Gradle workflow.
This patch introduces a different code path for building transitive dependencies, the new code path again assumes that all plugins support `android/`. Though no one notices, and no tests fail (the test introduced in #40640 passes as flutter_plugin_test isn’t included as a transitive dependency).


### 2019-12-06
In preparation for the new pub.dev version that supports multi platform federated plugins and for the coming stable Flutter release the team decides to start endorsing web plugins (by adding them as a dependency of the app-facing plugins, so e.g url_launcher_web becomes a dependency of url_launcher). When staging the first PR for url_launcher, CI alerts us that the example application fails building for Android. After some investigation amirh@ and blasten@ figure out that https://github.com/flutter/flutter/pull/45379 introduced the regression.

amirh@ starts adding a no-op `android/` implementations to the offending plugins, at the same time blasten@ sends https://github.com/flutter/flutter/pull/46282 which allows gradle to build apps with non Android plugins as transitive dependencies. At this point the release candidate for the next stable (1.12.13) was already cut without #46282.

The logic in #46282 is somewhat similar to #40640 and skips packages that do not have an `android/` folder, amirh@ asks blasten@ whether we should be consistent with #46282 and check for `android/build.gradle` but both figure it shouldn’t matter and the PR lands as-is.


### 2019-12-09
The web team makes the case that #46282 should be cherry picked into 1.12.13  to avoid adding no-op `android/` folders to all web implementations. It’s cherry picked into v.12.13+hotfix.4 and the team decides to not add any more no-op `android/` implementations and endorse the existing with a minimal Flutter SDK constraint of `>=1.12.13+hotfix.4`.

The team moves forward to publish the endorsements for: url_launcher, google_sign_in, video_player, firebase_auth, firebase_core, shared_preferences. At this point users of stable Flutter aren’t impacted as there is not yet a stable Flutter release which satisfies the version constraint, so pub won’t fetch the new plugin versions which include the endorsements.

### 2019-12-11
06:15pm - V1.12.13+hotfix.6 is released to stable **&lt;START OF OUTAGE&gt;**

At this point, users of any of {url_launcher, google_sign_in, video_player, firebase_auth, firebase_core, shared_preferences} are affected by 2 issues:
#### 1. Android Studio users can’t build their apps
Android studio automatically creates an `android/` folder for all the Gradle subprojects during the “analyzing project phase”. This essentially disables the fix in #46282. (note that it does not create a build.gradle file.)

This is not detected by CI as we’re not using Android Studio on CI.

#### 2. Non fully AndroidX-compatible projects fail to build
The Flutter tool has a backup build strategy to deal with AndroidX failures - if the first build attempt fails due to an AndroidX issue, the Flutter tool tries a secondary build strategy which builds all plugins as AARs (this enables Jettifier). This AAR workflow was not updated to support non-Android plugins, which guarantees the build retry will fail if any of the affected plugins are included as dependencies.


### 2019-12-12
10:45am - amirh@ skims over new Flutter issues and notices multiple reports on Gradle errors due to plugins missing Android support and files https://github.com/flutter/flutter/issues/46898 to start tracking.

While blasten@ is investigating the Gradle issue the team starts to mitigate by adding no-op `android/` implementations to the endorsed web plugins.

01:34pm - All endorsed web plugins got a no-op `android/` folder **&lt;END OF OUTAGE&gt;**

### 2019-12-13
blasten@ figures the underlying Gradle issue (https://github.com/flutter/flutter/issues/46898#issuecomment-565612416) and start working on a fix.


## Impact

Users of multiple popular Flutter plugins were not able to build their Android apps following an upgrade to Flutter V1.12.13+hotfix.6 and were getting uninformative Gradle failures.


## Root causes

 1. Web plugin implementations that did not include an Android implementation were endorsed by popular Flutter plugins relying on #46282.
 1. #46282 did not take into account that Android Studio may create an `android/` folder for subprojects.
 1. The AAR build workflow did not support non-Android implementations.

## Lessons learned


### What worked

 - The community was quick to report the new issue.
 - The team was quick to mitigate by applying a workaround to all plugins.

### Where we got lucky

 - amirh@ skimmed the Flutter issue database a day after the incident started and flags the issue. Normally issue triage meetings run on a weekly cadence so it could have taken a whole week until the issue was flagged.

### What didn't work

 - Non-Android transitive dependencies were not supported when Android Studio is used.
 - The AAR build workflow did not support non-Android dependencies.

## Action items

 - All endorsed plugin implementation should have a op-op Android implementation until the Gradle fixes are in stable. OWNER: amirh@ (DONE).
 - The `flutter.gradle` script should exclude non-Android plugins for transitive dependencies in a way that’s resilient to Android Studio side effects. OWNER: blasten@ (DONE).
 - The `flutter.gradle` script should exclude non-Android plugins in the AAR build workflow as well. OWNER: blasten@ (DONE).


### Detection

{link to github issues for things that would have detected this failure before it became An Incident, such as better testing, monitoring, etc}

 * All `dev/devicelab/bin/tasks/gradle_*` tests should run with the AAR workflow as well - https://github.com/flutter/flutter/issues/48089.
 * All `dev/devicelab/bin/tasks/gradle_*` tests should run with and without the projects being opened (and built?) by Android Studio - https://github.com/flutter/flutter/issues/48088.


### Process

{link to github issues for things that would have helped us resolve this failure faster, such as documented processes and protocols, etc}
 * A better process for flagging erupting fires quickly:
   * Alerts for issues that quickly gain thumb ups
   * Increased issue monitoring following a Flutter release

### Fixes

{link to github issues or PRs/commits for the actual fixes that were necessary to resolve this incident}

https://github.com/flutter/flutter/pull/47015
