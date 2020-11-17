# Flutter for Web Integration testing with `integration_test` package

These are web tests which are using `integration_test` (aka e2e) package. In order to run them locally, run `chromedriver`:

```
chromedriver --port=4444
```

For more details on running/downloading chromedriver, use the [link](https://chromedriver.chromium.org/getting-started).

Later use the following command:

```
flutter drive --target=test_driver/text_editing_integration.dart -d web-server --browser-name=chrome
```

For more details on running a Flutter Driver test on web use the [link](https://github.com/flutter/flutter/wiki/Running-Flutter-Driver-tests-with-Web)
For more details on `integration_test` package [link](https://pub.dev/packages/integration_test)
