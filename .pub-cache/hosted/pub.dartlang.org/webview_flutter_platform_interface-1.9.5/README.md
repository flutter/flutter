# webview_flutter_platform_interface

A common platform interface for the [`webview_flutter`](https://pub.dev/packages/webview_flutter) plugin.

This interface allows platform-specific implementations of the `webview_flutter`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `webview_flutter`, extend
[`WebviewPlatform`](lib/src/platform_interface/webview_platform.dart) with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`WebviewPlatform` by calling
`WebviewPlatform.setInstance(MyPlatformWebview())`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.
