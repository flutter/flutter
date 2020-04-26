# Splash Demo: Kitchen Sink

This project is an example of a splash screen that shows a logo for a launch screen and then
zooms that logo towards the screen while fading content beneath it, masked by the logo.

The purpose of this example project is to push the limits of what Flutter's splash system affords.

This project is also run as a device lab test via Flutter Driver.

The files that are relevant to test execution are:

 - /test_driver/main.dart
 - /test_driver/main_test.dart
 - /android/app/src/main/java/io/flutter/splash_screen_kitchen_sink/MainActivity.java

 The files that should be inspected to learn about splash behavior are:

 - /android/app/src/main/java/io/flutter/splash_screen_kitchen_sink/FlutterZoomSplashScreen.java
 - /android/app/src/main/java/io/flutter/splash_screen_kitchen_sink/FlutterZoomSplashView.java

 Communication takes place from Android to Flutter to Driver to communicate splash screen events.
 This communication takes place over a channel called "testChannel", whose definition can be
 found in `MainActivity.java` and `test_driver/main.dart`.
