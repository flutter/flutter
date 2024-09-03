# ios_prepare_pre_action_test

Previously, the Flutter framework was unpacked as part of the Xcode target's
build.

As part of the Swift Package Manager project, an Xcode Scheme Pre-Action was
added to unpack the Flutter framework. This ensures the Flutter framework
is available _before_ Swift Package Manager builds packages.

This test project was [manually edited to have the Xcode Scheme Pre-Action][] but
not Swift Package Manager integration. This allows us to test the Xcode Scheme
Pre-Action without requiring the Swift Package Manager feature.

This test project can be removed once the Swift Package Manager feature is
complete and test projects have been updated to have the Xcode Scheme Pre-Action
that prepares the Flutter framework. See:
https://github.com/flutter/flutter/issues/126005.

[manually edited to have the Xcode Scheme Pre-Action]: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#step-2-add-run-prepare-flutter-framework-script-pre-action
