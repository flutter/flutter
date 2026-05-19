# Deferred components integration test app

## Setup

This integration test app requires manually downloading additional assets to build. Run

`./download_assets.sh`

before running any of the tests.

## Tests

This app contains two sets of tests:

 * `flutter drive` tests that run a debug mode app to validate framework side logic
 * `run_release_test.sh <bundletool.jar path>` which builds and installs a release version of this app and
   validates the loading units are loaded correctly. A path to bundletool.jar must be provided
