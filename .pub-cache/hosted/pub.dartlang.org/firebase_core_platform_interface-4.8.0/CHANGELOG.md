## 4.8.0

 - **FEAT**: update dependency constraints to `sdk: '>=2.18.0 <4.0.0'` `flutter: '>=3.3.0'` ([#10946](https://github.com/firebase/flutterfire/issues/10946)). ([2772d10f](https://github.com/firebase/flutterfire/commit/2772d10fe510dcc28ec2d37a26b266c935699fa6))

## 4.7.0

 - **FEAT**(core): add support for Windows via Firebase C++ desktop SDK ([#10496](https://github.com/firebase/flutterfire/issues/10496)). ([c0b8ad56](https://github.com/firebase/flutterfire/commit/c0b8ad5605d1fda6d897ea625224b5e61c5826ad))
 - **FEAT**: upgrade to dart 3 compatible dependencies ([#10890](https://github.com/firebase/flutterfire/issues/10890)). ([4bd7e59b](https://github.com/firebase/flutterfire/commit/4bd7e59b1f2b09a2230c49830159342dd4592041))

## 4.6.0

 - **FEAT**: bump dart sdk constraint to 2.18 ([#10618](https://github.com/firebase/flutterfire/issues/10618)). ([f80948a2](https://github.com/firebase/flutterfire/commit/f80948a28b62eead358bdb900d5a0dfb97cebb33))

## 4.5.3

 - **REFACTOR**: upgrade project to remove warnings from Flutter 3.7 ([#10344](https://github.com/firebase/flutterfire/issues/10344)). ([e0087c84](https://github.com/firebase/flutterfire/commit/e0087c845c7526c11a4241a26d39d4673b0ad29d))

## 4.5.2

 - **REFACTOR**: add `verify` to `QueryPlatform` and change internal `verifyToken` API to `verify` ([#9711](https://github.com/firebase/flutterfire/issues/9711)). ([c99a842f](https://github.com/firebase/flutterfire/commit/c99a842f3e3f5f10246e73f51530cc58c42b49a3))

## 4.5.1

 - **FIX**: Prepare for fix to https://github.com/flutter/flutter/issues/109339. ([#9364](https://github.com/firebase/flutterfire/issues/9364)). ([7418dfd9](https://github.com/firebase/flutterfire/commit/7418dfd91c4fc7982c6bc6b1e8de80f9bccd575b))

## 4.5.0

 - **FEAT**: add phone MFA ([#9044](https://github.com/firebase/flutterfire/issues/9044)). ([1b85c8b7](https://github.com/firebase/flutterfire/commit/1b85c8b7fbcc3f21767f23981cb35061772d483f))

## 4.4.3

 - **FIX**: bump `firebase_core_platform_interface` version to fix previous release. ([bea70ea5](https://github.com/firebase/flutterfire/commit/bea70ea5cbbb62cbfd2a7a74ae3a07cb12b3ee5a))

## 4.4.2

 - Manual version to fix previous release.

## 4.4.1

 - **REFACTOR**: migrate from hash* to Object.hash* (#8797). ([3dfc0997](https://github.com/firebase/flutterfire/commit/3dfc0997050ee4351207c355b2c22b46885f971f))
 - **REFACTOR**: use "firebase" instead of "FirebaseExtended" as organisation in all links for this repository (#8791). ([d90b8357](https://github.com/firebase/flutterfire/commit/d90b8357db01d65e753021358668f0b129713e6b))

## 4.4.0

 - **FEAT**: allow initializing default Firebase apps via `FirebaseOptions.fromResource` on Android ([#8566](https://github.com/firebase/flutterfire/issues/8566)). ([30216c4a](https://github.com/firebase/flutterfire/commit/30216c4a4c06c20f9c4c2b9a235a4aa9a48816a0))

## 4.3.0

 - **FEAT**: allow initializing default Firebase apps via `FirebaseOptions.fromResource` on Android (#8566). ([30216c4a](https://github.com/firebase/flutterfire/commit/30216c4a4c06c20f9c4c2b9a235a4aa9a48816a0))

## 4.2.5

 - **FIX**: update all Dart SDK version constraints to Dart >= 2.16.0 (#8184). ([df4a5bab](https://github.com/firebase/flutterfire/commit/df4a5bab3c029399b4f257a5dd658d302efe3908))

## 4.2.4

 - **FIX**: allow secondary Firebase App initialization without duplicate app error on hot restart (#7953). ([f4a2c2e6](https://github.com/firebase/flutterfire/commit/f4a2c2e63e4dd4f888583110cc65ec84dec14dd7))
 - **FIX**: Fix `FirebaseException` error code bug by making default value: "unknown". (#6897). ([48fed37c](https://github.com/firebase/flutterfire/commit/48fed37c8e09b4c1c70f97488215fd39ff2f0616))

## 4.2.3

 - **REFACTOR**: fix all `unnecessary_import` analyzer issues introduced with Flutter 2.8. ([7f0e82c9](https://github.com/firebase/flutterfire/commit/7f0e82c978a3f5a707dd95c7e9136a3e106ff75e))

## 4.2.2

 - **FIX**: correctly detect `not-initialized` errors and provide a better error message. ([0578423e](https://github.com/firebase/flutterfire/commit/0578423e9868352556bfdd326eef1cca8dbe04aa))

## 4.2.1

 - **FIX**: loosen duplicate app detection checks to allow unset options not to cause a duplicate app exception (#7499).

## 4.2.0

 - **FEAT**: auto inject Firebase scripts (#7358).

## 4.1.0

 - **FEAT**: support initializing default `FirebaseApp` instances from Dart (#6549).

## 4.0.1

 - **FIX**: Fix FirebaseOptions hashCode (#3263).
 - **DOCS**: Add missing homepage/repository links (#6054).
 - **CHORE**: bump min Dart SDK constraint to 2.12.0 (#5430).
 - **CHORE**: merge all analysis_options.yaml into one (#5329).

## 4.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 4.0.0-1.0.nullsafety.1

 - **REFACTOR**: pubspec & dependency updates (#4932).

## 4.0.0-1.0.nullsafety.0

 - Bump "firebase_core_platform_interface" to `4.0.0-1.0.nullsafety.0`.

## 4.0.0-nullsafety.0

Major bump for the null-safety version to respect the versioning convention.

## 3.0.2-nullsafety.0

 - **REFACTOR**: Migrate to non-nullable types (#4656).

## 3.0.1

 - **DOCS**: installation links updated (#4479).

## 3.0.0

> Note: This release has breaking changes.

 - **BREAKING** **REFACTOR**: remove all currently deprecated APIs.

## 2.1.0

 - **FEAT**: add FirebaseException.stackTrace support (#4095).
 - **CHORE**: promote to stable version.

## 2.0.0

* DEPRECATED: `FirebaseApp.configure` method is now deprecated in favor of the `Firebase.initializeApp` method.
* DEPRECATED: `FirebaseApp.allApps` method is now deprecated in favor of the `Firebase.apps` property.
  * Previously, `allApps` was asynchronous where it is now synchronous.
* DEPRECATED: `FirebaseApp.appNamed` method is now deprecated in favor of the `Firebase.app` method.
* BREAKING: `FirebaseApp.options` getter is now synchronous.

* `FirebaseOptions` has been reworked to better match web property names:
  * DEPRECATED: `googleAppID` is now deprecated in favor of `appId`.
  * DEPRECATED: `projectID` is now deprecated in favor of `projectId`.
  * DEPRECATED: `bundleID` is now deprecated in favor of `bundleId`.
  * DEPRECATED: `clientID` is now deprecated in favor of `androidClientId`.
  * DEPRECATED: `trackingID` is now deprecated in favor of `trackingId`.
  * DEPRECATED: `gcmSenderID` is now deprecated in favor of `messagingSenderId`.
  * Added support for `authDomain`.
  * Added support for `trackingId`.
  * Required properties are now `apiKey`, `appId`, `messagingSenderId` & `projectId`.

* Added support for deleting Firebase app instances via the `delete` method on `FirebaseApp`.
* Added support for returning consistent error messages from `firebase-dart` plugin.
  * Any FlutterFire related errors now throw a `FirebaseException`.
* Added a `FirebaseException` class to handle all FlutterFire related errors.
  * Matching the web sdk, the exception returns a formatted "[plugin/code] message" message when thrown.
* Added support for `setAutomaticDataCollectionEnabled` & `isAutomaticDataCollectionEnabled` on a `FirebaseApp` instance.
* Added support for `setAutomaticResourceManagementEnabled` on a `FirebaseApp` instance.

## 1.0.5

* Update lower bound of dart dependency to 2.0.0.

## 1.0.4

* Migrate to package:plugin_platform_interface.

## 1.0.3

* Make the pedantic dev_dependency explicit.

## 1.0.2

- Remove the deprecated `author:` field from pubspec.yaml

## 1.0.1

- Switch away from quiver_hashcode.

## 1.0.0

- Initial open-source release.
