# Example of building a Flutter app for Android using Gradle

This project demonstrates how to embed Flutter within an Android application
and build the Android and Flutter components with Gradle.

To build this project:

* Create a `local.properties` file with these entries:
  * `sdk.dir=[path to the Android SDK]`
  * `flutter.sdk=[path to the Flutter SDK]`

Then run:

* `gradle wrapper`
* `./gradlew build`

## Updating the Dart code

You can push new Dart code to a Flutter app during development without performing
a full rebuild of the Android app package.

The `flutter refresh` tool manages this process.  `flutter refresh` will build
a snapshot of an app's Dart code, copy it to an Android device, and send an
intent instructing the Android app to load the snapshot.

To try this out:

* Install and run this app on your device
* Edit the Dart code in `app/src/flutter/lib`
* cd `app/src/flutter`
* `flutter refresh --activity com.example.flutter/.ExampleActivity`

`flutter refresh` sends an `ACTION_RUN` intent with an extra containing the
device filesystem path where the snapshot was copied.  `ExampleActivity.java`
shows how an activity can handle this intent and load the new snapshot into
a Flutter view.
