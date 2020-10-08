# Flutter for Web Integration testing with `integration_test` package

These are web tests which are using `integration_test` (aka e2e) package. In order to run them locally, run `chromedriver` on port 4444. Later use the following command:

```
flutter run test_driver/text_editing_integration.dart -d web-server --web-port=8080 --browser-name=chrome
```
