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

## Adding screenshot tests

In order to test screenshot tests the tests on the driver side needs to call the `integration_test` package with an `onScreenshot` callback which can do a comparison between the `screenshotBytes` taken during the test and a golden file. We added a utility method that can do this comparison by using a golden in `flutter/goldens` repository.

In order to use screenshot testing first, import `screenshot_support.dart` from the driver side test (example: `text_editing_integration_test.dart`). Default value for `diffRateFailure` is 0.5.

```
import 'package:regular_integration_tests/screenshot_support.dart' as test;

Future<void> main() async {
  final double kMaxDiffRateFailure = 0.1;
  await test.runTestWithScreenshots(diffRateFailure = kMaxDiffRateFailure);
}
```

In order to run the tests follow these steps:

1. You can use two different approaches, using [felt](https://github.com/flutter/engine/blob/master/lib/web_ui/dev/README.md) tool will run all the tests, hence update all the goldens. For running individual tests, we need to set UPDATE_GOLDENS environment variable. Screenshots are saved differently per browser, therefore do not forget to also update the screenshots for other browsers. Note that, LUCI is only running screenshot testing for integration tests on Firefox and Chrome.

```
felt test --integration-tests-only --update-screenshot-goldens
```

```
UPDATE_GOLDENS=true flutter drive -v --target=test_driver/text_editing_integration.dart -d web-server --release --local-engine=host_debug_unopt
```

```
UPDATE_GOLDENS=true flutter drive -v --target=test_driver/text_editing_integration.dart -d web-server --release --local-engine=host_debug_unopt --browser-name=firefox
```

2. The golden will be under `engine/src/flutter/lib/web_ui/.dart_tool/goldens/engine/web/` directory, you should create a PR for that file and merge it to `flutter/goldens`. For each browser the browser name would be appended to the end of the golden file such as: `screenshot_name-chrome.png` or `screenshot_name-firefox.png`

3. Get the commit SHA and replace the `revision` in this file: `engine/src/flutter/lib/web_ui/dev/goldens_lock.yaml`
