# Example of switching between full-screen Flutter and Platform View

This project demonstrates how to bring up a full-screen iOS view from a full-screen
Flutter view along with passing data back and forth between the two.

## iOS

On iOS we use a CocoaPods dependency to add a Material Design button, and so
`pod install` needs to be invoked in the `ios/` folder before `flutter run`:

pushd ios/ ; pod install ; popd
flutter run

## Android

We refer to the platform_channel project.
