# Templates for Flutter Module

## common

Written to root of Flutter module.

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

Mixin for adding Gradle boilerplate to Android projects. The `build.gradle`
file is a template file so that it is created, not copied, on instantiation.
That way, its timestamp reflects template instantiation time.

#### host_app_common

Written to either `.android/` or `android/`.

Contents define a single-Activity, single-View Android host app
with a dependency on the `.android/Flutter` library.

Executing `./gradlew app:assembleDebug` in the target folder produces
an `.apk` archive.

Used with either `android_host_ephemeral` or `android_host_materialized`.

#### host_app_ephemeral

Written to `.android/` on top of `android_host_common`.

Combined contents define an *ephemeral* (hidden, auto-generated,
under Flutter tooling control) Android host app with a dependency on the
`.android/Flutter` library.

#### host_app_materialized

Written to `android/` on top of `android_host_common`.

Combined contents define a *materialized* (visible, one-time generated,
under app author control) Android host app with a dependency on the
`.android/Flutter` library.

## ios

Written to the `.ios/` hidden folder.

Contents wraps Flutter/Dart code as a CocoaPods pod.

iOS host apps can set up a dependency to this project to consume
Flutter views.
