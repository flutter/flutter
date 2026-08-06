# Engine Integration Golden Test

This integration test suite validates engine related rendering tests using Skia Gold.

## Running Locally
```sh
flutter test dev/integration_tests/engine_integration_golden_test/integration_test/engine_integration_golden_test.dart -d <device_id>
```

## Running via Devicelab on Windows
```sh
cd dev/devicelab
dart bin/run.dart -t windows_engine_integration_golden_test
```
