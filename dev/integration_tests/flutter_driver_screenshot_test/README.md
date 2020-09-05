# Summary

This test contains an app with a main page and subpages.
The main page contains a list of buttons; each button leads to a designated subpage when tapped on.
Each subpage should display some simple UIs to the screenshot tested.

The flutter driver test runs the app and opens each page to take a screenshot.

Use `main_test.dart` to test against golden files stored on Flutter Gold.

Note that new binaries can't be checked in the Flutter repo, so use [Flutter Gold](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter) instead.

# Add a new page to test

1. Create a new class that extends `Page` and implement the UI to be tested in the `build` method.
2. The new class should set a static `title` and `key`
3. Add an instance of the new class to the `_allPages` list in the `main.dart`
4. Create a new test case similar to `"'A page with an image screenshot"` in `test_driver/main_test.dart` to run the screenshot test.

An example of a `Page` subclass can be found in `lib/image_page.dart`

# Environments

* Device Lab which runs the app on iPhone 6s.
* LUCI which runs the app on a Fuchsia NUC device.
