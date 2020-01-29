# Summary

This tests contains an app with a main page and sub pages.
The main page contains a list of buttons; each button leads to a designated sub page when tapped on.
Each sub page should displays some simple UIs to screenshot tested.

The flutter driver test runs the app and opens each page to take a screenshot. Then it compares the screenshot against a golden image stored in `test_driver/goldens/<some_test_page_name>/<device_model>.png`.

# Add a new page to test

1. Create a new class which extends `Page` and implement the UI to be tested in the `build` method.
2. The new class should set a static `title` and `key`
3. Add an instance of the new class to the `_allPages` list in the `main.dart`
4. Create a new test case similar to `"'A page with an image screenshot"` in `test_driver/main_test.dart` to run the screenshot test.
5. Create directories for the test: `test_driver/goldens/<some_test_page_name>` should be created before running the test based on the target platform the test is designed to run.

An example of a `Page` subclass can be found in `lib/image_page.dart`

# Experiments

The test currently only runs on device lab ["mac/ios"] which runs the app on iPhone 6s.