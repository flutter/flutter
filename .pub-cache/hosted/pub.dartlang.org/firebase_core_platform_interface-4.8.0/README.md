# firebase_core_platform_interface

A common platform interface for the [`firebase_core`][1] plugin.

This interface allows platform-specific implementations of the `firebase_core`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `firebase_core`, extend
[`FirebasePlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`FirebasePlatform` by calling
`FirebasePlatform.instance = MyFirebaseCore()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.

[1]: ../firebase_core
[2]: lib/firebase_core_platform_interface.dart
