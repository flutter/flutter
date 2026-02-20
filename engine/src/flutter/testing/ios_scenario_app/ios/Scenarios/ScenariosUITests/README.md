# Adding a New Scenario for a XCUITest

An XCUITest is different from a regular XCTest in that the test subject app runs
in a different process than the test suite, making it trickier for the test code
to communicate with the app. For instance, you won't have access to
the view controller or engine instances from within the test code.

For this reason, the test code typically uses **launch arguments** to configure
the app (for example, use [launchArgsMap](../Scenarios/AppDelegate.m) to inform
the app which `Scenario` to load), and use UIKit UI components to collect test
results (for example, every messsage received on the `display_data` channel adds
a new `UITextField` to the app, which will be visible to the test code. See [touches_scenario.dart](../../../lib/src/touches_scenario.dart) for an example).

Refer to the [Adding a New Scenario](./../../../README.md) section for how to
register a new dart `Scenario`.

#  Golden UI Tests

This folder contains golden image tests. It renders UI (for instance, a platform
view) and does a screen shot comparison against a known good configuration.

The screen shots are named `golden_[scenario name]_[MODEL]`, with `_simulator`
appended for simulators. The model numbers for physical devices correspond
to the `hw.model` sys call, and will represent the model numbers. Simulator
names are taken from the environment.

New devices require running the test on the device, gathering the attachment
from the test result and verifying it manually. Then adding an appropriately
named file to this folder.

If the test is attempted on a new device, the log will contain a message
indicating the file name it expected to find. The test will continue and fail,
but will contain an attachment with the expected screen shot. If the screen
shot looks good, add it with the correct name to the project and run the test
again - it should pass this time.

## Running a specific Scenario

Add and enable the new launch argument to the `Arguments Passed On Launch`
section of the `Debug - Run` scheme, and build and run the app.
