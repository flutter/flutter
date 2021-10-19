# Flutter Web integration tests

To run the tests in this package [download][1] the chromedriver matching the
version of Chrome. To find out the version of your Chrome installation visit chrome://version.
Start `chromedriver` using the following command:

```
chromedriver --port=4444
```

Here's an example of running an integration test:

```
flutter drive --target=test_driver/text_editing_integration.dart -d web-server --browser-name=chrome
```

More resources:

* chromedriver: https://chromedriver.chromium.org/getting-started
* FlutterDriver: https://github.com/flutter/flutter/wiki/Running-Flutter-Driver-tests-with-Web
* `package:integration_test`: https://pub.dev/packages/integration_test

[1]: https://chromedriver.chromium.org/downloads
