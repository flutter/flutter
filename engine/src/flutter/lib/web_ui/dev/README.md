## What's `felt`?

`felt` stands for "Flutter Engine Local Tester". It's a cli tool that aims to make development in the Flutter web engine more productive and pleasant.

## What can `felt` do?

`felt` supports multiple commands as follows:

1. **`felt check-licenses`**: Checks that all Dart and JS source code files contain the correct license headers.
2. **`felt test`**: Runs all or some tests depending on the passed arguments.
3. **`felt build`**: Builds the engine locally so it can be used by Flutter apps. It also supports a watch mode for more convenience.

You could also run `felt help` or `felt help <command>` to get more information about the available commands and arguments.

## How can I use `felt`?

Once you have your local copy of the engine [setup](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment), it's recommended that you add `/path/to/engine/src/flutter/lib/web_ui/dev` to your `PATH`.
Then you would be able to use the `felt` tool from anywhere:

```
felt check-licenses
```

or:

```
felt build --watch
```

If you don't want to add `felt` to your path, you can still invoke it using a relative path like `./web_ui/dev/felt <command>`

## Speeding up your builds and tests

If you are a Google employee, you can use an internal instance of Goma to parallelize your builds. Because Goma compiles code on remote servers, this option is effective even on low-powered laptops.

By default, when compiling Dart code to JavaScript, we use 8 `dart2js` workers.

## Running web engine tests

To run all tests on Chrome. This will run both integration tests and the unit tests:

```
felt test
```

To run unit tests only:

```
felt test --unit-tests-only
```

To run integration tests only. For now these tests are only available on Chrome Desktop browsers. These tests will fetch the flutter repository for using `flutter drive` and `flutter pub get` commands. The repository will be synced to the youngest commit older than the engine commit.

```
felt test --integration-tests-only
```

To skip cloning the flutter repository use the following flag. This flag can save internet bandwidth. However use with caution. Note the tests results will not be consistent with CIs when this flag is set. flutter command should be set in the PATH for this flag to be useful. This flag can also be used to test local Flutter changes.

```
felt test --integration-tests-only --use-system-flutter
```

To run tests on Firefox (this will work only on a Linux device):

```
felt test --browser=firefox
```

For Chrome and Firefox, the tests run on a version locked on the [browser_lock.yaml](https://github.com/flutter/engine/blob/master/lib/web_ui/dev/browser_lock.yaml). In order to use another version, add the version argument:

```
felt test --browser=firefox --firefox-version=70.0.1
```

To run tests on Safari use the following command. It works on macOS devices and it uses the Safari installed on the OS. Currently there is no option for using another Safari version.

```
felt test --browser=safari
```

One can also use Safari running in iOS Simulator for running unit tests. There are few prerequisite steps:

1. Please make sure that you installed Xcode.

2. The default version used in the tests are in browser_lock.yaml file. Install the ios version to use for simulators: Xcode > Preferences > Components

3. run `xcrun simctl list devices`. If the simulator you want is not installed use step 4.

4. Use felt to create a simulator:

```
felt create_simulator --type='iOS' --version='13.1' --device='iPhone.11.Pro'
```

To run tests on ios-safari use the one of the following commands:

```
felt test --browser=ios-safari
felt test --browser=ios-safari --version='13.1' --device='iPhone.11.Pro'
felt test --browser=ios-safari test/alarm_clock_test.dart
```

To run tests on Windows Edge use the following command. It works on Windows devices and it uses the Edge installed on the OS.

```
felt_windows.bat test --browser=edge
```

To run a single test use the following command. Note that it does not work on Windows.

```
felt test test/golden_tests/engine/canvas_golden_test.dart
```

To debug a test on Chrome:

```
felt test --debug test/golden_tests/engine/canvas_golden_test.dart
```

## Configuration files

`browser_lock.yaml` contains the version of browsers we use to test Flutter for
web. Versions are not automatically updated whenever a new release is available.
Instead, we update this file manually once in a while.

`goldens_lock.yaml` refers to a revision in the https://github.com/flutter/goldens
repo. Screenshot tests are compared with the golden files at that revision.
When making engine changes that affect screenshots, first submit a PR to
flutter/goldens updating the screenshots. Then update this file pointing to
the new revision.

## Developing the `felt` tool

If you are making changes in the `felt` tool itself, you need to be aware of Dart snapshots. We create a Dart snapshot of the `felt` tool to make the startup faster.

To make sure you are running the `felt` tool with your changes included, you would need to stop using the snapshot. This can be achived through the environment variable `FELT_USE_SNAPSHOT`:

```
FELT_USE_SNAPSHOT=false felt <command>
```

or

```
FELT_USE_SNAPSHOT=0 felt <command>
```

_**Note**: if `FELT_USE_SNAPSHOT` is omitted or has any value other than "false" or "0", the snapshot mode will be enabled._

## Upgrade Browser Version

Since the engine code and infra recipes do not live in the same repository there are few steps to follow in order to upgrade a browser's version. For now these instructins are most relevant to Chrome.

1. Dowload the binaries for the new browser/driver for each operaing system (macOS, linux, windows).
2. Create CIPD packages for these packages. (More documentation is available for Googlers. go/cipd-flutter-web)
3. Add the new browser version to the recipe. Do not remove the old one. This recipe will apply to all PRs as soon as it is merged. However, not all PRs will have the up to date code for a while.
4. Update the version in this repo. Do this by changing the related fields in `browser_lock.yaml` file.
5. After a few days don't forget to remove the old version from the LUCI recipe.

Note that for LUCI builders, both unit and integration tests are using the same browser.

Some useful links:

1. For Chrome downloads [link](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html)
2. Browser and driver CIPD [packages](https://chrome-infra-packages.appspot.com/p/flutter_internal) (Note: Access rights are restricted for these packages.)
3. LUCI web [recipe](https://flutter.googlesource.com/recipes/+/refs/heads/master/recipes/web_engine.py)
4. More general reading on CIPD packages [link](https://chromium.googlesource.com/chromium/src.git/+/master/docs/cipd.md#What-is-CIPD)
