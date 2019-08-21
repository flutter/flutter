#  PlatformView UI Tests

This folder contains a test for platform views. It renders a platform view
and does a screen shot comparison against a known good configuration.

The screen shots are named `golden_platform_view_MODEL`, with `_simulator`
appended for simulators. The model numbers for physical devices correspond
to the `hw.model` sys call, and will represent the model numbers. Simulator
names are taken from the environment.

New devices require running the test on the device, gathering the attachment
and verifying it manually, and then adding an appropriately named file to
this folder.
