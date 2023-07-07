## 2.0.15

* Fixes Java lints.
* Updates minimum supported SDK version to Flutter 3.3/Dart 2.18.

## 2.0.14

* Fixes compatibility with ActivityPluginBinding.

## 2.0.13

* Fixes compatibility with AGP versions older than 4.2.

## 2.0.12

* Adds `targetCompatibilty` matching `sourceCompatibility` for older toolchains.

## 2.0.11

* Adds a namespace for compatibility with AGP 8.0.

## 2.0.10

* Sets an explicit Java compatibility version.
* Aligns Dart and Flutter SDK constraints.

## 2.0.9

* Updates annotation and espresso dependencies.
* Updates compileSdkVersion to 33.

## 2.0.8

* Updates links for the merge of flutter/plugins into flutter/packages.
* Updates minimum Flutter version to 3.0.

## 2.0.7

* Bumps gradle from 3.5.0 to 7.2.1.

## 2.0.6

* Adds OS version support information to README.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.0.5

* Updates compileSdkVersion to 31.

## 2.0.4

* Updated Android lint settings.
* Remove placeholder Dart file.

## 2.0.3

* Remove references to the Android V1 embedding.

## 2.0.2

* Migrate maven repo from jcenter to mavenCentral.

## 2.0.1

* Make sure androidx.lifecycle.DefaultLifecycleObservable doesn't get shrunk away.

## 2.0.0

* Bump Dart SDK for null-safety compatibility.
* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))

## 1.0.12

* Update Flutter SDK constraint.

## 1.0.11

* Keep handling deprecated Android v1 classes for backward compatibility.

## 1.0.10

* Update android compileSdkVersion to 29.

## 1.0.9

* Let the no-op plugin implement the `FlutterPlugin` interface.

## 1.0.8

* Post-v2 Android embedding cleanup.

## 1.0.7

* Update Gradle version. Fixes https://github.com/flutter/flutter/issues/48724.
* Fix CocoaPods podspec lint warnings.

## 1.0.6

* Make the pedantic dev_dependency explicit.

## 1.0.5

* Add notice in example this plugin only provides Android Lifecycle API.

## 1.0.4

* Require Flutter SDK 1.12.13 or greater.
* Change to avoid reflection.

## 1.0.3

* Remove the deprecated `author:` field from pubspec.yaml
* Require Flutter SDK 1.10.0 or greater.

## 1.0.2

* Adapt to the embedding API changes in https://github.com/flutter/engine/pull/13280 (only supports Activity Lifecycle).

## 1.0.1
* Register the E2E plugin in the example app.

## 1.0.0

* Introduces a `FlutterLifecycleAdapter`, which can be used by other plugins to obtain a `Lifecycle`
  reference from a `FlutterPluginBinding`.
