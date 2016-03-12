# Example of building a Flutter app for Android using Gradle

This project demonstrates how to embed Flutter within an Android application
and build the Android and Flutter components with Gradle.

To build this project:

* Create a `local.properties` file with these entries:
  * `sdk.dir=[path to the Android SDK]`
  * `flutter.sdk=[path to the Flutter SDK]`
  * `flutter.jar=[path to the flutter.jar file in your build of the Flutter engine]`

Then run:

* `gradle wrapper`
* `./gradlew build`
