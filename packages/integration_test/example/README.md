# integration_test_example

Demonstrates how to use the `package:integration_test`.

To run `integration_test/example_test.dart`,

## Android / iOS

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/example_test.dart
```

## Web

In one shell, run Chromedriver ([download
here](https://chromedriver.chromium.org/downloads)):

```
chromedriver --port 8444
```

Then, in another shell, run `flutter drive`:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/example_test.dart \
  -d web-server
```
