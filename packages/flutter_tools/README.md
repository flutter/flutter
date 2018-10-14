# Flutter Tools

Tools for building Flutter applications.

## Setup

To setup, firstly go to the repository root and run the script to download
the appropriate version of Dart SDK into the bin folder:

```shell
./bin/internal/update_dart_sdk.sh
```

Then, navigate to `flutter_tools` and run `pub get` to download dependencies,
but using the downloaded version of Dart:

```shell
../../bin/cache/dart-sdk/bin/pub get
```

## Tests

To run the tests, ensure that no devices are connected,
then navigate to `flutter_tools` and execute:

```shell
../../bin/cache/dart-sdk/bin/pub run test
```
