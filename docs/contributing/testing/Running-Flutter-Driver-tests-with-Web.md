In the last months Flutter Driver tests has been enabled for most browsers.

This document explains the steps that should be followed before running the tests, how to run the tests, example usages and handy tools that can be used.

## Preparing the driver

The first step of using Flutter Driver tests for Flutter Web testing is to install(prepare) the driver for the target browser.

### Using Chrome

For Chrome Desktop browsers:

- Check the version of Chrome.
- Download the Chrome driver for that version from [driver downloads](https://chromedriver.chromium.org/downloads).
- Start the driver on port 4444. `chromedriver --port=4444`

Chrome on Android browser tests can be run both on device and on the emulator.

- Both for using a real device and emulator, make sure that Android platform tools are installed
- For using an emulator, follow the [instructions](https://developer.android.com/studio/run/managing-avds) for creating and managing one.
- For real device tests check the devices Chrome's version. Please note that the Chrome installed on the emulator will probably have a different version than the host machine. Check the emulator's Chrome's version.
- Download the driver [driver downloads](https://chromedriver.chromium.org/downloads).
- Start the adb server: `adb start-server` you can later kill with `adb kill-server`
- For the web port you are planning to use for Flutter driver tests, let's say 8080 for example:
  - Test the browser has access to a server running on localhost:8080
  - One can utilize adb for this purpose. For more [details](https://developer.android.com/studio/command-line/adb).
  - Another alternative is using Chrome Remote devices from browser page `chrome://inspect/devices#devices`. For more details on useful links: [remote debugging webviews](https://developers.google.com/web/tools/chrome-devtools/remote-debugging/webviews), [remote debugging android devices](https://developers.google.com/web/tools/chrome-devtools/remote-debugging)
- Start the Chrome driver on port 4444. `chromedriver --port=4444`

### Using Safari

Like Safari browser Safari driver also comes installed on the macOS devices. For using Safari on macOS steps are easy:

- Use the [instructions](https://developer.apple.com/documentation/webkit/testing_with_webdriver_in_safari) to enable safari driver.
- start safari driver on port 4444 `./usr/bin/safaridriver  --port=4444`

IOS Safari can be run on a simulator. Simulators are part of Xcode, more [details](https://developer.apple.com/documentation/xcode). After making sure your macOS have simulators, follow the steps above to start the Safari driver. Unlike Android the Desktop Safari version and simulator version is the same.

### Using Firefox

- Check the version of Firefox.
- Download the Gecko driver for that version from [the releases](https://github.com/mozilla/geckodriver/releases).
- Add the Firefox driver to your path.

Note that this section is experimental, at this point we don't have automated tests running on Firefox.

### Using Edge

More information can be found on Edge Drivers on [developer site](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/). Edge driver should also be added to the path after installation.

Note that this section is experimental, at this point we don't have automated tests running on Edge.

## Running Flutter Driver tests

The command for running the driver tests:

```
flutter drive --target=test_driver/[driver_test].dart -d web-server --release --browser-name=chrome --web-port=8080
```

Let's go over the different arguments that can be used:

- Use one of the six browsers for `--browser-name` parameter: chrome, safari, ios-safari, android-chrome, firefox, edge.
- Use `--local-engine=host_debug_unopt --local-engine-host=host_debug_unopt` for running tests with a local engine.
- Use `--release` or `--profile` mode for running the tests. Debug mode will be supported soon.
- Change the `--webport` as needed, don't forget to change remote debugging settings for Android Chrome.
- Use `--no-android-emulator` for using Android with real devices.

## Web Installers Repo

Web installers is a new Flutter project [repository](https://github.com/flutter/web_installers) where we are planning to add utilities for launching, downloading browsers/drivers.

Currently it can be used for downloading/running Chrome Driver:

```
dart lib/web_driver_installer.dart chromedriver --driver-version="78.0.3904.105"
```

Or for running the Safari driver:

```
dart lib/web_driver_installer.dart safaridriver
```

For more details use the [documentation](https://github.com/flutter/web_installers/tree/master/packages/web_drivers).

## Examples From Flutter Project

We already use Flutter Driver in many different places in Flutter Project. We have a smoke test running as a [Cirrus CI task](https://github.com/flutter/flutter/blob/main/.cirrus.yml#L291) in Flutter repo, which is also a great example for showing web_installers + flutter drive usage.

```
script:
        - flutter config --enable-web
        - git clone https://github.com/flutter/web_installers.git
        - cd web_installers/packages/web_drivers/
        - pub get
        - dart lib/web_driver_installer.dart &
        - sleep 20
        - chromedriver/chromedriver --port=4444 &
        - sleep 5
        - cd ../../../examples/hello_world/
        - flutter drive --target=test_driver/smoke_web_engine.dart -d web-server --profile --browser-name=chrome
```

Other example usages:

- e2e tests under flutter/packages repo. ([PR](https://github.com/flutter/plugins/pull/2554))
- web engine integration tests under engine repo. ([PR](https://github.com/flutter/engine/pull/16930))
