## 6.1.16

* Updates Guava to version 32.0.1.

## 6.1.15

* Updates minimum supported SDK version to Flutter 3.3/Dart 2.18.
* Updates Guava to version 32.0.0.

## 6.1.14

* Fixes compatibility with AGP versions older than 4.2.

## 6.1.13

* Adds `targetCompatibilty` matching `sourceCompatibility` for older toolchains.

## 6.1.12

* Adds a namespace for compatibility with AGP 8.0.

## 6.1.11

* Fixes Java warnings.

## 6.1.10

* Sets an explicit Java compatibility version.

## 6.1.9

* Updates play-services-auth version to 20.5.0.

## 6.1.8

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.
* Updates compileSdkVersion to 33.

## 6.1.7

* Updates links for the merge of flutter/plugins into flutter/packages.

## 6.1.6

* Minor implementation cleanup
* Updates minimum Flutter version to 3.0.

## 6.1.5

* Updates play-services-auth version to 20.4.1.

## 6.1.4

* Rolls Guava to version 31.1.

## 6.1.3

* Updates play-services-auth version to 20.4.0.

## 6.1.2

* Fixes passing `serverClientId` via the channelled `init` call

## 6.1.1

* Corrects typos in plugin error logs and removes not actionable warnings.
* Updates minimum Flutter version to 2.10.
* Updates play-services-auth version to 20.3.0.

## 6.1.0

* Adds override for `GoogleSignIn.initWithParams` to handle new `forceCodeForRefreshToken` parameter.

## 6.0.1

* Updates gradle version to 7.2.1 on Android.

## 6.0.0

* Deprecates `clientId` and adds support for `serverClientId` instead.
  Historically `clientId` was interpreted as `serverClientId`, but only on Android. On
  other platforms it was interpreted as the OAuth `clientId` of the app. For backwards-compatibility
  `clientId` will still be used as a server client ID if `serverClientId` is not provided.
* **BREAKING CHANGES**:
  * Adds `serverClientId` parameter to `IDelegate.init` (Java).

## 5.2.8

* Suppresses `deprecation` warnings (for using Android V1 embedding).

## 5.2.7

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 5.2.6

* Switches to an internal method channel, rather than the default.

## 5.2.5

* Splits from `google_sign_in` as a federated implementation.
