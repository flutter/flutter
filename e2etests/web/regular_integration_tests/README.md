# Flutter for Web Engine Integration testing

This directory is for Flutter Web engine integration tests that does not need a specific configuration. If an integration test needs specialized app configuration (e.g. PWA vs non-PWA packaging), please create another directory under e2etests/web. Otherwise tests such as text_editing, history, scrolling, pointer events... should all go under this package.

Tests can be run on both 'debug', 'release' and 'profile' modes. However 'profile'/'release' modes will shorten the error stack trace. 'release' mode is for testing release code. Use 'debug' mode for troubleshooting purposes and seeing full stack traces (if there is an error). For more details on build [modes](https://flutter.dev/docs/testing/build-modes).

## To run the application under test for troubleshooting purposes

```
flutter run -d web-server lib/text_editing_main.dart --local-engine=host_debug_unopt
```

## To run the Text Editing test and use the developer tools in the browser

```
flutter run test_driver/text_editing_integration.dart -d web-server --web-port=8080 --profile --local-engine=host_debug_unopt
```

## To run the test for Text Editing with driver

Either of the following options:

```
flutter drive -v --target=test_driver/text_editing_integration.dart -d web-server --profile --local-engine=host_debug_unopt
```

```
flutter drive -v --target=test_driver/text_editing_integration.dart -d web-server --release --local-engine=host_debug_unopt
```

## Using different browsers

The default browser is Chrome, you can also use `android-chrome`, `safari`,`ios-safari`, `firefox` or `edge` as your browser choice. Example:

```
flutter drive -v --target=test_driver/text_editing_integration.dart -d web-server --release --browser-name=firefox --local-engine=host_debug_unopt
```

More details for "Running Flutter Driver tests with Web" can be found in [wiki](https://github.com/flutter/flutter/wiki/Running-Flutter-Driver-tests-with-Web).
