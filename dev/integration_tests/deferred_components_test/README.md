# Deferred components integration test app

## Tests

This app contains two sets of tests:

 * `flutter drive` tests that run a debug mode app to validate framework side logic
 * `run_release_test.sh <bundletool.jar path>` which builds and installs a release version of this app and
   validates the loading units are loaded correctly. A path to bundletool.jar must be provided
