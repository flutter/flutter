# high_bitrate_images

An integration test used for testing high bitrate image support in the engine.

## Local run

```sh
flutter create --platforms="ios" --no-overwrite .
flutter drive \
  --target=integration_test/app_test.dart \
  --driver=test_driver/integration_test.dart
```
