# Templates for Flutter Module

## common

Written to root of Flutter application.

Adds Dart project files including `pubspec.yaml`.

## android

#### library

Written to the `.android/` hidden folder.

Contents wraps Flutter/Dart code as a Gradle project that defines an
Android library.

Executing `./gradlew flutter:assembleDebug` in that folder produces
a `.aar` archive.

Android host apps can set up a dependency to this project to consume
Flutter views.

#### gradle

Written to `.android/` or `android/`.

Mixin for adding Gradle boilerplate to Android projects.

#### host_app_common

Written to either `.android/` or `android/`.

Contents define a single-Activity, single-View Android host app
with a dependency on the `.android/Flutter` library.

Executing `./gradlew app:assembleDebug` in the target folder produces
an `.apk` archive.

Used with either `android_host_ephemeral` or `android_host_editable`.

#### host_app_ephemeral

Written to `.android/` on top of `android_host_common`.

Combined contents define an *ephemeral* (hidden, auto-generated,
under Flutter tooling control) Android host app with a dependency on the
`.android/Flutter` library.

#### host_app_editable

Written to `android/` on top of `android_host_common`.

Combined contents define an *editable* (visible, one-time generated,
under app author control) Android host app with a dependency on the
`.android/Flutter` library.

## ios

#### library

Written to the `.ios/Flutter` hidden folder.

Contents wraps Flutter/Dart code for consumption by an Xcode project.

iOS host apps can set up a dependency to this contents to consume
Flutter views.

#### host_app_ephemeral

Written to `.ios/` outside the `Flutter/` sub-folder.

Combined contents define an *ephemeral* (hidden, auto-generated,
under Flutter tooling control) iOS host app with a dependency on the
`.ios/Flutter` folder contents.

The host app does not make use of CocoaPods, and is therefore
suitable only when the Flutter part declares no plugin dependencies.

#### host_app_ephemeral_cocoapods

Written to `.ios/` on top of `host_app_ephemeral`.

Adds CocoaPods support.

Combined contents define an ephemeral host app suitable for when the
Flutter part declares plugin dependencies.
