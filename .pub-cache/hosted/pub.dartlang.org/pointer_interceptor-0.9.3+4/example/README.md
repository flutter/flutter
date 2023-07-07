# pointer_interceptor_example

An example for the PointerInterceptor widget.

## Getting Started

`flutter run -d chrome` to run the sample. You can tweak some code in the `lib/main.dart`, but be careful, changes there can break integration tests!

## Running tests

`flutter drive --target integration_test/widget_test.dart --driver test_driver/integration_test.dart --show-web-server-device -d web-server --web-renderer=html`

The command above will run the integration tests for this package.

Make sure that you have `chromedriver` running in port `4444`.

Read more on: [flutter.dev > Docs > Testing & debugging > Integration testing](https://flutter.dev/docs/testing/integration-tests).
