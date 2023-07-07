# Platform Implementation Test App

This is a test app for manual testing and automated integration testing
of this platform implementation. It is not intended to demonstrate actual use of
this package, since the intent is that plugin clients use the app-facing
package.

Unless you are making changes to this implementation package, this example is
very unlikely to be relevant.

## Testing

This package uses `package:integration_test` to run its tests in a web browser.

See [Plugin Tests > Web Tests](https://github.com/flutter/flutter/wiki/Plugin-Tests#web-tests)
in the Flutter wiki for instructions to setup and run the tests in this package.

Check [flutter.dev > Integration testing](https://flutter.dev/docs/testing/integration-tests)
for more info.

# button_tester.dart

The button_tester.dart file contains an example app to test the different configuration
values of the Google Sign In Button Widget.

To run that example:

```console
$ flutter run -d chrome --target=lib/button_tester.dart
```
