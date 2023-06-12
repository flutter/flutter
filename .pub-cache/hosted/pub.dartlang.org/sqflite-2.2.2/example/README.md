# sqflite_example

Demonstrates how to use the [sqflite plugin](https://github.com/tekartik/sqflite).

## Quick test

    flutter run
    
Specific app entry point
    
    flutter run -t lib/main.dart

## Android

Some project files is no longer in source control but can be re-created using

    flutter create --platforms android .

### Tests

    cd android

    # Java unit test
    ./gradlew test

    # With a emulator running
    ./gradlew connectedAndroidTest

## iOS

Project files are no longer in source control but can be re-created using

    flutter create --platforms ios .

## MacOS

Project files are no longer in source control but can be re-created using

    flutter create --platforms macos .
    flutter run -d macos

