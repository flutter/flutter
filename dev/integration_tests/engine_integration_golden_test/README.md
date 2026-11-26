# Engine Integration Golden Test

This integration test suite validates engine related rendering tests using Skia Gold.

## Running Locally
```sh
cd dev/integration_tests/engine_integration_golden_test
flutter test integration_test/engine_integration_golden_test.dart -d <device_id>
```

## Running via Devicelab on Windows
```sh
cd dev/devicelab
dart bin/run.dart -t windows_engine_integration_golden_test
```

`windows_engine_integration_golden_test_feature_level_10_0` runs the same tests
with the engine's D3D11 feature level capped to 10_0 (via
`FLUTTER_WINDOWS_MAX_D3D_FEATURE_LEVEL`) and compares against a separate set of
goldens.
