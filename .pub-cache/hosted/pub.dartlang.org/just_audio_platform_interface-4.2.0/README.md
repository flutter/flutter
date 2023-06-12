# just_audio_platform_interface

A common platform interface for the [`just_audio`](../just_audio) plugin.

This interface allows platform-specific implementations of the `just_audio` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

# Usage

To implement a new platform-specific implementation of `just_audio`, extend [`JustAudioPlatform`](lib/just_audio_platform_interface.dart) with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default `JustAudioPlatform` by calling `JustAudioPlatform.instance = MyPlatformJustAudio()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface) over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion on why a less-clean interface is preferable to a breaking change.
