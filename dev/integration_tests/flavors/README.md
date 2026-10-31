# flavors

Integration test of build flavors (Android product flavors, Xcode schemes).

The `free` and `paid` flavors each select a different configuration file from
`configs/`, using `bundle_path: assets/branch-config.json`. The integration test
checks that Dart's `rootBundle` and the Android/iOS native asset APIs read the
same selected file at that fixed key. The fixtures contain no SDK keys and do
not initialize the Branch SDK.

Run the full integration test with the `paid` flavor, or just the configuration
lookup test with either flavor:

```sh
flutter test integration_test/integration_test.dart --flavor paid -d <device>
flutter test integration_test/integration_test.dart --flavor free -d <device> --plain-name 'loads the selected configuration'
```
