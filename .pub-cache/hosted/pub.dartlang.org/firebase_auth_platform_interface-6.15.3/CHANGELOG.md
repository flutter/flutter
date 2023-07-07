## 6.15.3

 - Update a dependency to the latest release.

## 6.15.2

 - Update a dependency to the latest release.

## 6.15.1

 - Update a dependency to the latest release.

## 6.15.0

 - **FEAT**: update dependency constraints to `sdk: '>=2.18.0 <4.0.0'` `flutter: '>=3.3.0'` ([#10946](https://github.com/firebase/flutterfire/issues/10946)). ([2772d10f](https://github.com/firebase/flutterfire/commit/2772d10fe510dcc28ec2d37a26b266c935699fa6))
 - **FEAT**: update librairies to be compatible with Flutter 3.10.0 ([#10944](https://github.com/firebase/flutterfire/issues/10944)). ([e1f5a5ea](https://github.com/firebase/flutterfire/commit/e1f5a5ea798c54f19d1d2f7b8f2250f8819f44b7))

## 6.14.0

 - **FEAT**: upgrade to dart 3 compatible dependencies ([#10890](https://github.com/firebase/flutterfire/issues/10890)). ([4bd7e59b](https://github.com/firebase/flutterfire/commit/4bd7e59b1f2b09a2230c49830159342dd4592041))

## 6.13.1

 - Update a dependency to the latest release.

## 6.13.0

 - **FEAT**: bump dart sdk constraint to 2.18 ([#10618](https://github.com/firebase/flutterfire/issues/10618)). ([f80948a2](https://github.com/firebase/flutterfire/commit/f80948a28b62eead358bdb900d5a0dfb97cebb33))

## 6.12.0

 - **FIX**(auth): fix an issue where unenroll would not throw a FirebaseException ([#10572](https://github.com/firebase/flutterfire/issues/10572)). ([8dba33e1](https://github.com/firebase/flutterfire/commit/8dba33e1a95f03d70d527885aa58ce23622e359f))
 - **FEAT**(auth): improve error handling when using beforeSignIn functions blocks sign in ([#10611](https://github.com/firebase/flutterfire/issues/10611)). ([b48e0952](https://github.com/firebase/flutterfire/commit/b48e0952ff32fe1dd07651727573156db2be5643))
 - **FEAT**(auth): improve error handling when Email enumeration feature is on ([#10591](https://github.com/firebase/flutterfire/issues/10591)). ([ff083025](https://github.com/firebase/flutterfire/commit/ff083025b724d683cc3a9ed5f4a4987c43663589))

## 6.11.12

 - Update a dependency to the latest release.

## 6.11.11

 - Update a dependency to the latest release.

## 6.11.10

 - Update a dependency to the latest release.

## 6.11.9

 - Update a dependency to the latest release.

## 6.11.8

 - **REFACTOR**: upgrade project to remove warnings from Flutter 3.7 ([#10344](https://github.com/firebase/flutterfire/issues/10344)). ([e0087c84](https://github.com/firebase/flutterfire/commit/e0087c845c7526c11a4241a26d39d4673b0ad29d))

## 6.11.7

 - Update a dependency to the latest release.

## 6.11.6

 - Update a dependency to the latest release.

## 6.11.5

 - **FIX**: null check fix that could happen when using verifyPhone ([#10119](https://github.com/firebase/flutterfire/issues/10119)). ([575c0ccb](https://github.com/firebase/flutterfire/commit/575c0ccbb4d9bf3875e8de0b2131c59ede869754))

## 6.11.4

 - **FIX**: properly cast the PlatformException to FirebaseAuthException ([#10058](https://github.com/firebase/flutterfire/issues/10058)). ([6c8f9515](https://github.com/firebase/flutterfire/commit/6c8f951552ba7f767ce1b7b7ea5328454ba28cce))

## 6.11.3

 - Update a dependency to the latest release.

## 6.11.2

 - Update a dependency to the latest release.

## 6.11.1

 - Update a dependency to the latest release.

## 6.11.0

 - **REFACTOR**: add `verify` to `QueryPlatform` and change internal `verifyToken` API to `verify` ([#9711](https://github.com/firebase/flutterfire/issues/9711)). ([c99a842f](https://github.com/firebase/flutterfire/commit/c99a842f3e3f5f10246e73f51530cc58c42b49a3))
 - **FEAT**: expose reauthenticateWithRedirect and reauthenticateWithPopup ([#9696](https://github.com/firebase/flutterfire/issues/9696)). ([2a1f910f](https://github.com/firebase/flutterfire/commit/2a1f910ff6cab21a126c62fd4322a14ec263b629))

## 6.10.4

 - Update a dependency to the latest release.

## 6.10.3

 - Update a dependency to the latest release.

## 6.10.2

 - Update a dependency to the latest release.

## 6.10.1

 - **FIX**: Exceptions inside Query.snapshots() and more now have a stack trace that correctly points to the invocation of the throwing method ([#9639](https://github.com/firebase/flutterfire/issues/9639)). ([2f7adcb7](https://github.com/firebase/flutterfire/commit/2f7adcb777cd6bc4e3b5b3dd03c975c725bacef7))
 - **DOCS**: update `setSettings()` inline documentation ([#9655](https://github.com/firebase/flutterfire/issues/9655)). ([39ca0029](https://github.com/firebase/flutterfire/commit/39ca00299ec5c6e0f2dc9b0b5a8d71b8d59d51d4))

## 6.10.0

 - **FEAT**: add OAuth Access Token support to sign in with providers ([#9593](https://github.com/firebase/flutterfire/issues/9593)). ([cb6661bb](https://github.com/firebase/flutterfire/commit/cb6661bbc701031d6f920ace3a6efc8e8d56aa4c))
 - **FEAT**: add `linkWithRedirect` to the web ([#9580](https://github.com/firebase/flutterfire/issues/9580)). ([d834b90f](https://github.com/firebase/flutterfire/commit/d834b90f29fc1929a195d7d546170e4ea03c6ab1))

## 6.9.0

 - **FIX**: fix path of generated Pigeon files to prevent name collision ([#9569](https://github.com/firebase/flutterfire/issues/9569)). ([71bde27d](https://github.com/firebase/flutterfire/commit/71bde27d4e613096f121abb16d7ea8483c3fbcd8))
 - **FEAT**: add `reauthenticateWithProvider` ([#9570](https://github.com/firebase/flutterfire/issues/9570)). ([dad6b481](https://github.com/firebase/flutterfire/commit/dad6b4813c682e35315dda3965ea8aaf5ba030e8))

## 6.8.0

 - **REFACTOR**: deprecate `signInWithAuthProvider` in favor of `signInWithProvider` ([#9542](https://github.com/firebase/flutterfire/issues/9542)). ([ca340ea1](https://github.com/firebase/flutterfire/commit/ca340ea19c8dbb340f083e48cf1b0de36f7d64c4))
 - **FEAT**: add `linkWithProvider` to support for linking auth providers ([#9535](https://github.com/firebase/flutterfire/issues/9535)). ([1ac14fb1](https://github.com/firebase/flutterfire/commit/1ac14fb147f83cf5c7874004a9dc61838dce8da8))

## 6.7.0

 - **FIX**: fix enrollementTimestamp parsing on Web ([#9440](https://github.com/firebase/flutterfire/issues/9440)). ([639cab7b](https://github.com/firebase/flutterfire/commit/639cab7b84aa33cc1dda144fc89db2236a1945b2))
 - **FEAT**: add Twitter login for Android, iOS and Web ([#9421](https://github.com/firebase/flutterfire/issues/9421)). ([0bc6e6d5](https://github.com/firebase/flutterfire/commit/0bc6e6d5333e6be0d5749a083206f3f5bb79a7ba))
 - **FEAT**: add Yahoo as provider for iOS, Android and Web ([#9443](https://github.com/firebase/flutterfire/issues/9443)). ([6c3108a7](https://github.com/firebase/flutterfire/commit/6c3108a767aca3b1a844b2b5da04b2da45bc9fbd))
 - **DOCS**: fix typo "apperance" in `platform_interface_firebase_auth.dart` ([#9472](https://github.com/firebase/flutterfire/issues/9472)). ([323b917b](https://github.com/firebase/flutterfire/commit/323b917b5eecf0e5161a61c66f6cabac5b23e1b8))

## 6.6.0

 - **FEAT**: add Microsoft login for Android, iOS and Web ([#9415](https://github.com/firebase/flutterfire/issues/9415)). ([1610ce8a](https://github.com/firebase/flutterfire/commit/1610ce8ac96d6da202ef014e9a3dfeb4acfacec9))
 - **FEAT**: add Sign in with Apple directly in Firebase Auth for Android, iOS 13+ and Web ([#9408](https://github.com/firebase/flutterfire/issues/9408)). ([da36b986](https://github.com/firebase/flutterfire/commit/da36b9861b7d635382705b4893eed85fd672125c))

## 6.5.4

 - **FIX**: fix an error where MultifactorInfo factorId could be null on iOS ([#9367](https://github.com/firebase/flutterfire/issues/9367)). ([88bded11](https://github.com/firebase/flutterfire/commit/88bded119607473c7546154ac8bdd149a2d3f21f))

## 6.5.3

 - **FIX**: use correct UTC time from server for `currentUser?.metadata.creationTime` & `currentUser?.metadata.lastSignInTime` ([#9248](https://github.com/firebase/flutterfire/issues/9248)). ([a6204128](https://github.com/firebase/flutterfire/commit/a6204128edf1f54ac734385d0ed6214d50cebd1b))
 - **DOCS**: explicit mention that `refreshToken` is empty string on native platforms on the `User`instance ([#9183](https://github.com/firebase/flutterfire/issues/9183)). ([1aa1c163](https://github.com/firebase/flutterfire/commit/1aa1c1638edc632dedf8de0f02127e26b1a86e17))
 - **DOCS**: add note that `persistence` is only available on web based platforms. ([#9274](https://github.com/firebase/flutterfire/issues/9274)). ([3ad2485c](https://github.com/firebase/flutterfire/commit/3ad2485ccdcce2eb9634bd7f005479a03b3265ef))

## 6.5.2

 - **DOCS**: update `getIdTokenResult` inline documentation ([#9150](https://github.com/firebase/flutterfire/issues/9150)). ([519518ce](https://github.com/firebase/flutterfire/commit/519518ce3ed36580e35713e791281b251018201c))

## 6.5.1

 - **FIX**: restore default persistence to IndexedDB that was incorrectly set to localStorage ([#9247](https://github.com/firebase/flutterfire/issues/9247)). ([785c4869](https://github.com/firebase/flutterfire/commit/785c4869a45be039d3f1b1473380a1d08609c28e))

## 6.5.0

 - **FIX**: pass `Persistence` value to `FirebaseAuth.instanceFor(app: app, persistence: persistence)` for setting persistence on Web platform ([#9138](https://github.com/firebase/flutterfire/issues/9138)). ([ae7ebaf8](https://github.com/firebase/flutterfire/commit/ae7ebaf8e304a2676b2acfa68aadf0538468b4a0))
 - **FEAT**: expose the missing MultiFactor classes through the universal package ([#9194](https://github.com/firebase/flutterfire/issues/9194)). ([d8bf8185](https://github.com/firebase/flutterfire/commit/d8bf818528c3705350cdb1b4675d600ba1d29d14))

## 6.4.0

 - **FEAT**: add phone MFA ([#9044](https://github.com/firebase/flutterfire/issues/9044)). ([1b85c8b7](https://github.com/firebase/flutterfire/commit/1b85c8b7fbcc3f21767f23981cb35061772d483f))

## 6.3.2

 - Update a dependency to the latest release.

## 6.3.1

 - **FIX**: bump `firebase_core_platform_interface` version to fix previous release. ([bea70ea5](https://github.com/firebase/flutterfire/commit/bea70ea5cbbb62cbfd2a7a74ae3a07cb12b3ee5a))

## 6.3.0

 - **FEAT**: update GitHub sign in implementation (#8976). ([ffd3b019](https://github.com/firebase/flutterfire/commit/ffd3b019c3158c66476671d9a9df245035cc2295))

## 6.2.8

 - **REFACTOR**: use "firebase" instead of "FirebaseExtended" as organisation in all links for this repository (#8791). ([d90b8357](https://github.com/firebase/flutterfire/commit/d90b8357db01d65e753021358668f0b129713e6b))

## 6.2.7

 - Update a dependency to the latest release.

## 6.2.6

 - **REFACTOR**: fix analyzer issues introduced in Flutter 3.0.0 ([#8653](https://github.com/firebase/flutterfire/issues/8653)). ([74e58171](https://github.com/firebase/flutterfire/commit/74e5817159f18934ed0cd803f410ec96b372316a))

## 6.2.5

 - Update a dependency to the latest release.

## 6.2.4

 - Update a dependency to the latest release.

## 6.2.3

 - Update a dependency to the latest release.

## 6.2.2

 - Update a dependency to the latest release.

## 6.2.1

 - **FIX**: update all Dart SDK version constraints to Dart >= 2.16.0 (#8184). ([df4a5bab](https://github.com/firebase/flutterfire/commit/df4a5bab3c029399b4f257a5dd658d302efe3908))

## 6.2.0

 - **FEAT**: refactor error handling to preserve stack traces on platform exceptions (#8156). ([6ac77d99](https://github.com/firebase/flutterfire/commit/6ac77d99042de2a1950f89b35972e3ee1116dc9f))

## 6.1.11

 - Update a dependency to the latest release.

## 6.1.10

 - Update a dependency to the latest release.

## 6.1.9

 - **REFACTOR**: fix all `unnecessary_import` analyzer issues introduced with Flutter 2.8. ([7f0e82c9](https://github.com/firebase/flutterfire/commit/7f0e82c978a3f5a707dd95c7e9136a3e106ff75e))

## 6.1.8

 - Update a dependency to the latest release.

## 6.1.7

 - **DOCS**: Fix typos and remove unused imports (#7504).

## 6.1.6

 - Update a dependency to the latest release.

## 6.1.5

 - Update a dependency to the latest release.

## 6.1.4

 - Update a dependency to the latest release.

## 6.1.3

 - Update a dependency to the latest release.

## 6.1.2

 - Update a dependency to the latest release.

## 6.1.1

 - **TEST**: Fix pre-existing HintCode.UNNECESSARY_TYPE_CHECK_TRUE (#6931).
 - **FIX**: allow setLanguage to accept null (#7050).

## 6.1.0

 - **FEAT**: Add support for `secret` on `OAuthCredential` on web (#6830).
 - **FEAT**: expose linkWithPopup() & correctly parse credentials in exceptions (#6562).

## 6.0.1

 - Update a dependency to the latest release.

## 6.0.0

> Note: This release has breaking changes.

 - **FEAT**: setSettings now possible for android (#6367).
 - **CHORE**: publish packages (#6513).
 - **BREAKING** **FEAT**: use<product>Emulator(host, port) API update (#6439).

## 5.0.0

> Note: This release has breaking changes.

 - **FEAT**: setSettings now possible for android (#6367).
 - **BREAKING** **FEAT**: useAuthEmulator(host, port) API update.

## 4.3.1

 - Update a dependency to the latest release.

## 4.3.0

 - **FEAT**: add tenantId support  (#5736).

## 4.2.4

 - Update a dependency to the latest release.

## 4.2.3

 - Update a dependency to the latest release.

## 4.2.2

 - **DOCS**: Add missing homepage/repository links (#6054).
 - **CHORE**: publish packages (#6022).
 - **CHORE**: publish packages.

## 4.2.1

 - **FIX**: authentication forceResendingToken int can be null on iOS (#5944).

## 4.2.0

 - **FIX**: Move communication to EventChannels (#4643).
 - **FEAT**: OAuthProvider.parameters is now non-nullable (#5656).
 - **DOCS**: remove implicit-cast in the doc of AuthProviders (#5862).

## 4.1.1

 - **REFACTOR**: fix formatting (#5835).
 - **FIX**: uid can be null (#5834).
 - **FIX**: ensure web is initialized before sending stream events (#5766).
 - **CI**: review changes.

## 4.1.0

 - **FEAT**: PhoneAuthProvider.credential and PhoneAuthProvider.credentialFromToken now return a PhoneAuthCredential (#5675).

## 4.0.2

 - **DOCS**: userChanges clarification (#5698).

## 4.0.1

 - Update a dependency to the latest release.

## 4.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 4.0.0-1.1.nullsafety.3

 - **FIX**: Fix email link signin on Android (#4973).

## 4.0.0-1.1.nullsafety.2

 - **TESTS**: update mockito API usage in tests

## 4.0.0-1.1.nullsafety.1

 - **REFACTOR**: pubspec & dependency updates (#4932).

## 4.0.0-1.1.nullsafety.0

 - **FEAT**: implement support for `useEmulator` (#4263).

## 4.0.0-1.0.nullsafety.0

 - **FIX**: bump firebase_core_* package versions to updated NNBD versioning format (#4832).

## 4.0.0-nullsafety.1

Bump firebase_core to v0.8.0-nullsafety.1


## 4.0.0-nullsafety.0

Migrated to null safety (#4633)

## 3.0.1

 - Update a dependency to the latest release.

## 3.0.0

> Note: This release has breaking changes.

 - **FIX**: bubble exceptions (#3700).
 - **BREAKING** **REFACTOR**: remove all currently deprecated APIs (#4590).

## 2.1.4

 - Update a dependency to the latest release.

## 2.1.3

 - Update a dependency to the latest release.

## 2.1.2

 - **FIX**: fix firebase_auth listeners assigning of currentUser (#3737).

## 2.1.1

 - Update a dependency to the latest release.

## 2.1.0

 - **FIX**: fix IdTokenResult timestamps (web, ios) (#3357).
 - **FEAT**: add support for linkWithPhoneNumber (#3436).
 - **FEAT**: use named arguments for ActionCodeSettings (#3269).
 - **FEAT**: implement signInWithPhoneNumber on web (#3205).
 - **FEAT**: expose smsCode (android only) (#3308).
 - **DOCS**: fixed signOut method documentation (#3342).

## 2.0.1

* Fixed an incorrect assert when creating a `GoogleAuthCredential` instance. [(#3216)](https://github.com/firebase/flutterfire/pull/3216/files#diff-be71096f90f1a879f17b7c94607b0885)

## 2.0.0

* See the `firebase_auth` plugin changelog.

## 1.1.8

* Update lower bound of dart dependency to 2.0.0.

## 1.1.7

* Use package:plugin_platform_interface

## 1.1.6

* Make the pedantic dev_dependency explicit.

## 1.1.5

- Fixed typo on private method name.

## 1.1.4

- **Breaking change**: Added missing `app` parameter to `confirmPasswordReset`.
  (This is an exception to the usual policy of avoiding breaking changes since
  `confirmPasswordReset` is a new API and doesn't have clients yet.)

## 1.1.3

- Added support for `confirmPasswordReset`

## 1.1.2

- Remove the deprecated `author:` field from pubspec.yaml

## 1.1.1

- Fixed crash when platform returns an auth result where `additionalUserInfo`
  is not provided.

## 1.1.0

- Added type `PlatformOAuthCredential` for generic OAuth providers.

## 1.0.0

- Initial open-source release.
