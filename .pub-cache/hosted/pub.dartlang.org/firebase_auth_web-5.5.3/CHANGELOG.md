## 5.5.3

 - **FIX**(core): Omit unnecessary libraries for web ([#10068](https://github.com/firebase/flutterfire/issues/10068)). ([8659d4ed](https://github.com/firebase/flutterfire/commit/8659d4ed805ac92964c2c92d55192f6ef40d721a))

## 5.5.2

 - Update a dependency to the latest release.

## 5.5.1

 - Update a dependency to the latest release.

## 5.5.0

 - **FEAT**: update dependency constraints to `sdk: '>=2.18.0 <4.0.0'` `flutter: '>=3.3.0'` ([#10946](https://github.com/firebase/flutterfire/issues/10946)). ([2772d10f](https://github.com/firebase/flutterfire/commit/2772d10fe510dcc28ec2d37a26b266c935699fa6))
 - **FEAT**: update librairies to be compatible with Flutter 3.10.0 ([#10944](https://github.com/firebase/flutterfire/issues/10944)). ([e1f5a5ea](https://github.com/firebase/flutterfire/commit/e1f5a5ea798c54f19d1d2f7b8f2250f8819f44b7))

## 5.4.0

 - **FEAT**: upgrade to dart 3 compatible dependencies ([#10890](https://github.com/firebase/flutterfire/issues/10890)). ([4bd7e59b](https://github.com/firebase/flutterfire/commit/4bd7e59b1f2b09a2230c49830159342dd4592041))

## 5.3.2

 - Update a dependency to the latest release.

## 5.3.1

 - **FIX**(auth,web): fix support for hot reload with multiple named instances when using an emulator on Web ([#10766](https://github.com/firebase/flutterfire/issues/10766)). ([b5de275d](https://github.com/firebase/flutterfire/commit/b5de275d9278e4be04d25c6f5f512fbcd53a103b))

## 5.3.0

 - **FEAT**: bump dart sdk constraint to 2.18 ([#10618](https://github.com/firebase/flutterfire/issues/10618)). ([f80948a2](https://github.com/firebase/flutterfire/commit/f80948a28b62eead358bdb900d5a0dfb97cebb33))

## 5.2.10

 - **FIX**(auth): fix an issue where unenroll would not throw a FirebaseException ([#10572](https://github.com/firebase/flutterfire/issues/10572)). ([8dba33e1](https://github.com/firebase/flutterfire/commit/8dba33e1a95f03d70d527885aa58ce23622e359f))

## 5.2.9

 - **FIX**(auth,web): fix currentUser being null when using emulator or named instance ([#10565](https://github.com/firebase/flutterfire/issues/10565)). ([11e8644d](https://github.com/firebase/flutterfire/commit/11e8644df402a5abbb0d0c37714879272dec024c))

## 5.2.8

 - Update a dependency to the latest release.

## 5.2.7

 - Update a dependency to the latest release.

## 5.2.6

 - Update a dependency to the latest release.

## 5.2.5

 - Update a dependency to the latest release.

## 5.2.4

 - Update a dependency to the latest release.

## 5.2.3

 - revert dependency `Intl` to 0.17.0

## 5.2.2

 - Update a dependency to the latest release.

## 5.2.1

 - Update a dependency to the latest release.

## 5.2.0

 - **FIX**: properly cast the PlatformException to FirebaseAuthException ([#10058](https://github.com/firebase/flutterfire/issues/10058)). ([6c8f9515](https://github.com/firebase/flutterfire/commit/6c8f951552ba7f767ce1b7b7ea5328454ba28cce))
 - **FIX**: `currentUser` is now populated right at the start of the application without needing to wait for `authStateChange` ([#10028](https://github.com/firebase/flutterfire/issues/10028)). ([2bd0dbff](https://github.com/firebase/flutterfire/commit/2bd0dbffb081370da051ec52859b924e1cf06fca))
 - **FEAT**: add SAMLProvider support to Web ([#10075](https://github.com/firebase/flutterfire/issues/10075)). ([d4c27da1](https://github.com/firebase/flutterfire/commit/d4c27da1589c07f890e67fa11f10e277f19e1570))

## 5.1.3

 - **FIX**: catch hot reload & hot restart exception for web emulator ([#9601](https://github.com/firebase/flutterfire/issues/9601)). ([3467483b](https://github.com/firebase/flutterfire/commit/3467483be993a65f76203400721dc07e0729cac3))

## 5.1.2

 - Update a dependency to the latest release.

## 5.1.1

 - **FIX**: use correct UTC time from server for _webUser.metadata.creationTime & _webUser.metadata.lastSignInTime ([#9789](https://github.com/firebase/flutterfire/issues/9789)). ([44ac2a36](https://github.com/firebase/flutterfire/commit/44ac2a3665a1006d444b4725c131ad4f084fe3d1))

## 5.1.0

 - **FIX**: properly propagate the `FirebaseAuthMultiFactorException` for all reauthenticate and link methods ([#9700](https://github.com/firebase/flutterfire/issues/9700)). ([9ad97c82](https://github.com/firebase/flutterfire/commit/9ad97c82ead0f5c6f1307625374c34e0dcde730b))
 - **FEAT**: expose reauthenticateWithRedirect and reauthenticateWithPopup ([#9696](https://github.com/firebase/flutterfire/issues/9696)). ([2a1f910f](https://github.com/firebase/flutterfire/commit/2a1f910ff6cab21a126c62fd4322a14ec263b629))

## 5.0.2

 - Update a dependency to the latest release.

## 5.0.1

- Update a dependency to the latest release.

## 5.0.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: Firebase iOS SDK version: `10.0.0` ([#9708](https://github.com/firebase/flutterfire/issues/9708)). ([9627c56a](https://github.com/firebase/flutterfire/commit/9627c56a37d657d0250b6f6b87d0fec1c31d4ba3))

## 4.6.1

 - Update a dependency to the latest release.

## 4.6.0

 - **FEAT**: add OAuth Access Token support to sign in with providers ([#9593](https://github.com/firebase/flutterfire/issues/9593)). ([cb6661bb](https://github.com/firebase/flutterfire/commit/cb6661bbc701031d6f920ace3a6efc8e8d56aa4c))
 - **FEAT**: add `linkWithRedirect` to the web ([#9580](https://github.com/firebase/flutterfire/issues/9580)). ([d834b90f](https://github.com/firebase/flutterfire/commit/d834b90f29fc1929a195d7d546170e4ea03c6ab1))

## 4.5.0

 - **FEAT**: add `reauthenticateWithProvider` ([#9570](https://github.com/firebase/flutterfire/issues/9570)). ([dad6b481](https://github.com/firebase/flutterfire/commit/dad6b4813c682e35315dda3965ea8aaf5ba030e8))

## 4.4.1

 - Update a dependency to the latest release.

## 4.4.0

 - **FIX**: fix enrollementTimestamp parsing on Web ([#9440](https://github.com/firebase/flutterfire/issues/9440)). ([639cab7b](https://github.com/firebase/flutterfire/commit/639cab7b84aa33cc1dda144fc89db2236a1945b2))
 - **FEAT**: add Yahoo as provider for iOS, Android and Web ([#9443](https://github.com/firebase/flutterfire/issues/9443)). ([6c3108a7](https://github.com/firebase/flutterfire/commit/6c3108a767aca3b1a844b2b5da04b2da45bc9fbd))

## 4.3.0

 - **FEAT**: add Microsoft login for Android, iOS and Web ([#9415](https://github.com/firebase/flutterfire/issues/9415)). ([1610ce8a](https://github.com/firebase/flutterfire/commit/1610ce8ac96d6da202ef014e9a3dfeb4acfacec9))
 - **FEAT**: add Sign in with Apple directly in Firebase Auth for Android, iOS 13+ and Web ([#9408](https://github.com/firebase/flutterfire/issues/9408)). ([da36b986](https://github.com/firebase/flutterfire/commit/da36b9861b7d635382705b4893eed85fd672125c))

## 4.2.4

 - Update a dependency to the latest release.

## 4.2.3

 - Update a dependency to the latest release.

## 4.2.2

 - Update a dependency to the latest release.

## 4.2.1

 - **FIX**: restore default persistence to IndexedDB that was incorrectly set to localStorage ([#9247](https://github.com/firebase/flutterfire/issues/9247)). ([785c4869](https://github.com/firebase/flutterfire/commit/785c4869a45be039d3f1b1473380a1d08609c28e))

## 4.2.0

 - **FIX**: pass `Persistence` value to `FirebaseAuth.instanceFor(app: app, persistence: persistence)` for setting persistence on Web platform ([#9138](https://github.com/firebase/flutterfire/issues/9138)). ([ae7ebaf8](https://github.com/firebase/flutterfire/commit/ae7ebaf8e304a2676b2acfa68aadf0538468b4a0))
 - **FEAT**: expose the missing MultiFactor classes through the universal package ([#9194](https://github.com/firebase/flutterfire/issues/9194)). ([d8bf8185](https://github.com/firebase/flutterfire/commit/d8bf818528c3705350cdb1b4675d600ba1d29d14))

## 4.1.1

 - **FIX**: provide `browserPopupRedirectResolver` on init ([#9146](https://github.com/firebase/flutterfire/issues/9146)). ([bf1d9be1](https://github.com/firebase/flutterfire/commit/bf1d9be11a59475be173b01184efb53d92d152fe))

## 4.1.0

 - **FEAT**: add all providers available to MFA ([#9159](https://github.com/firebase/flutterfire/issues/9159)). ([5a03a859](https://github.com/firebase/flutterfire/commit/5a03a859385f0b06ad9afe8e8c706c046976b8d8))
 - **FEAT**: add phone MFA ([#9044](https://github.com/firebase/flutterfire/issues/9044)). ([1b85c8b7](https://github.com/firebase/flutterfire/commit/1b85c8b7fbcc3f21767f23981cb35061772d483f))

## 4.0.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: upgrade auth web to Firebase v9 JS SDK ([#8236](https://github.com/firebase/flutterfire/issues/8236)). ([8e95a51d](https://github.com/firebase/flutterfire/commit/8e95a51d99ffc5fec106d933e46c9f331c1e2d50))
 - **BREAKING**: Cannot set `updateDisplayName()` or `updatePhotoURL()` to `null` on web anymore.

## 3.3.19

 - **FIX**: bump `firebase_core_platform_interface` version to fix previous release. ([bea70ea5](https://github.com/firebase/flutterfire/commit/bea70ea5cbbb62cbfd2a7a74ae3a07cb12b3ee5a))

## 3.3.18

 - **FIX**: Web recaptcha hover removed after use. (#8812). ([790e450e](https://github.com/firebase/flutterfire/commit/790e450e8d6acd2fc50e0232c77a152430c7b3ea))

## 3.3.17

 - **REFACTOR**: use "firebase" instead of "FirebaseExtended" as organisation in all links for this repository (#8791). ([d90b8357](https://github.com/firebase/flutterfire/commit/d90b8357db01d65e753021358668f0b129713e6b))

## 3.3.16

 - Update a dependency to the latest release.

## 3.3.15

 - Update a dependency to the latest release.

## 3.3.14

 - Update a dependency to the latest release.

## 3.3.13

 - Update a dependency to the latest release.

## 3.3.12

 - Update a dependency to the latest release.

## 3.3.11

 - **FIX**: Allow `rawNonce` to be passed through on web via the `OAuthCredential`. (#8410). ([0df32f61](https://github.com/firebase/flutterfire/commit/0df32f6106ca41cdb95c36c7816e6487124937d4))

## 3.3.10

 - **FIX**: Check if `UserMetadata` properties are `null` before parsing. (#8313). ([cac41fb9](https://github.com/firebase/flutterfire/commit/cac41fb9ddd5462b57f9d17615f387478f10d3dc))

## 3.3.9

 - **FIX**: update all Dart SDK version constraints to Dart >= 2.16.0 (#8184). ([df4a5bab](https://github.com/firebase/flutterfire/commit/df4a5bab3c029399b4f257a5dd658d302efe3908))

## 3.3.8

 - Update a dependency to the latest release.

## 3.3.7

 - **FIX**: Add support for`dynamicLinkDomain` property to `ActionCodeSetting` for web. (#7683). ([3b0bf76e](https://github.com/firebase/flutterfire/commit/3b0bf76e015c95840b2d38eec7f12c001d3bd47c))

## 3.3.6

 - Update a dependency to the latest release.

## 3.3.5

 - Update a dependency to the latest release.

## 3.3.4

 - Update a dependency to the latest release.

## 3.3.3

 - Update a dependency to the latest release.

## 3.3.2

 - Update a dependency to the latest release.

## 3.3.1

 - Update a dependency to the latest release.

## 3.3.0

 - **FEAT**: automatically inject Firebase JS SDKs (#7359).

## 3.2.0

 - **FEAT**: support initializing default `FirebaseApp` instances from Dart (#6549).

## 3.1.4

 - Update a dependency to the latest release.

## 3.1.3

 - Update a dependency to the latest release.

## 3.1.2

 - **FIX**: null-safety migration issue for web types (#7137).

## 3.1.1

 - **FIX**: allow setLanguage to accept null (#7050).

## 3.1.0

 - **FEAT**: Add support for `secret` on `OAuthCredential` on web (#6830).
 - **FEAT**: expose linkWithPopup() & correctly parse credentials in exceptions (#6562).

## 3.0.1

 - Update a dependency to the latest release.

## 3.0.0

> Note: This release has breaking changes.

 - **FEAT**: setSettings now possible for android (#6367).
 - **CHORE**: catch native error verifyBeforeUpdateEmail() (#6473).
 - **BREAKING** **FEAT**: use<product>Emulator(host, port) API update (#6439).

## 2.0.0

> Note: This release has breaking changes.

 - **FEAT**: setSettings now possible for android (#6367).
 - **CHORE**: catch native error verifyBeforeUpdateEmail() (#6473).
 - **BREAKING** **FEAT**: useAuthEmulator(host, port) API update.

## 1.3.1

 - Update a dependency to the latest release.

## 1.3.0

 - **FEAT**: add tenantId support  (#5736).

## 1.2.0

 - **FEAT**: add User.updateDisplayName and User.updatePhotoURL (#6213).

## 1.1.3

 - Update a dependency to the latest release.

## 1.1.2

 - **DOCS**: Add missing homepage/repository links (#6054).
 - **CHORE**: publish packages (#6022).
 - **CHORE**: publish packages.

## 1.1.1

 - Update a dependency to the latest release.

## 1.1.0

 - **FEAT**: OAuthProvider.parameters is now non-nullable (#5656).

## 1.0.7

 - **FIX**: ensure web is initialized before sending stream events (#5766).
 - **CHORE**: update Web plugins to use Firebase JS SDK version 8.4.1 (#4464).

## 1.0.6

 - Update a dependency to the latest release.

## 1.0.5

 - Update a dependency to the latest release.

## 1.0.4

 - Update a dependency to the latest release.

## 1.0.3

 - Update a dependency to the latest release.

## 1.0.2

 - Update a dependency to the latest release.

## 1.0.1

 - **FIX**: correct use of underlying useEmulator API, sync not async (#5171).

## 1.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 1.0.0-1.0.nullsafety.0

 - Bump "firebase_auth_web" to `1.0.0-1.0.nullsafety.0`.

## 0.4.0-1.1.nullsafety.3

 - Update a dependency to the latest release.

## 0.4.0-1.1.nullsafety.2

 - Update a dependency to the latest release.

## 0.4.0-1.1.nullsafety.1

 - **REFACTOR**: pubspec & dependency updates (#4932).

## 0.4.0-1.1.nullsafety.0

 - **FEAT**: implement support for `useEmulator` (#4263).

## 0.4.0-1.0.nullsafety.0

 - **FIX**: bump firebase_core_* package versions to updated NNBD versioning format (#4832).

## 0.4.0-nullsafety.1

Bump firebase_auth_platform_interface to v4.0.0-nullsafety.1

## 0.4.0-nullsafety.0

Migrated to null safety (#4633)

## 0.3.2+6

 - Update a dependency to the latest release.

## 0.3.2+5

 - **FIX**: Revert #4312: Double event fire on initialization (#4620).

## 0.3.2+4

 - **FIX**: bubble exceptions (#3700).

## 0.3.2+3

 - **FIX**: web now fires once on authStateListener initialisation (#4312).

## 0.3.2+2

 - Update a dependency to the latest release.

## 0.3.2+1

 - Update a dependency to the latest release.

## 0.3.2

 - **FEAT**: migrate firebase interop files to local repository (#3973).
 - **FEAT** [WEB] adds support for `EmailAuthProvider.credentialWithLink`
 - **FEAT** [WEB] adds support for `FirebaseAuth.setSettings`
 - **FEAT** [WEB] adds support for `User.tenantId`
 - **FEAT** [WEB] `FirebaseAuthException` now supports `email` & `credential` properties
 - **FEAT** [WEB] `ActionCodeInfo` now supports `previousEmail` field

## 0.3.1+2

 - Update a dependency to the latest release.

## 0.3.1+1

 - Update a dependency to the latest release.

## 0.3.1

 - **FIX**: fix IdTokenResult timestamps (web, ios) (#3357).
 - **FIX**: force locale timestamp conversion (#3320).
 - **FIX**: implement missing web confirmPasswordReset (#3344).
 - **FIX**: send userPlatform on changes (#3313).
 - **FEAT**: add support for linkWithPhoneNumber (#3436).
 - **FEAT**: use named arguments for ActionCodeSettings (#3269).
 - **FEAT**: implement signInWithPhoneNumber on web (#3205).

## 0.3.0+1

* Bump `firebase_auth_platform_interface` dependency to fix an assertion issue when creating Google sign-in credentials.

## 0.3.0

* See the `firebase_auth` plugin changelog.
* Depend on `firebase_core`.

## 0.1.3+1

* Implement `confirmPasswordReset`.

## 0.1.3

* Update lower bound of dart dependency to 2.0.0.

## 0.1.2+2

* Make the pedantic dev_dependency explicit.

## 0.1.2+1

* Require `firebase_core_web` from hosted

## 0.1.2

* Implement `fetchSignInMethodsForEmail`, `isSignInWithEmailLink`, `signInWithEmailAndLink`, and `sendLinkToEmail`.

## 0.1.1+4

* Prevent `null` users (unauthenticated) from breaking the `onAuthStateChanged` Stream.
* Migrate tests from jsify to package:js.

## 0.1.1+3

* Fix the tests on dart2js.

## 0.1.1+2

* Update setup instructions in the README.

## 0.1.1+1

* Add an android/ folder with no-op implementation to workaround https://github.com/flutter/flutter/issues/46898

## 0.1.1

* Require Flutter SDK version 1.12.13+hotfix.4 or later.
* Add fake podspec so we don't break compilation on iOS.
* Fix homepage.

## 0.1.0+2

* Remove the deprecated `author:` field from pubspec.yaml.
* Bump the minimum Flutter version to 1.10.0.

## 0.1.0+1

* Fixed serialization error for creationTime and lastSignInTime being RFC 1123.

## 0.1.0

* Initial open-source release.
