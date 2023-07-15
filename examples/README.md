Flutter Examples
================

This directory contains several examples of using Flutter. To run an example,
use `flutter run` inside that example's directory. See the [getting started
guide](https://flutter.dev/getting-started/) to install the `flutter` tool.

For additional samples, see the
[`flutter/samples`](https://github.com/flutter/samples) repo.

Available examples include:

- **Hello, world** The [hello world app](hello_world) is a minimal Flutter app
  that shows the text "Hello, world!"

- **Flutter gallery** The flutter gallery app no longer lives in this repo.
  Please see the [gallery repo](https://github.com/flutter/gallery).

- **Layers** The [layers vignettes](layers) show how to use the various layers
  in the Flutter framework. For details, see the [layers
  README](layers/README.md).

- **Platform Channel** The [platform channel app](platform_channel) demonstrates
  how to connect a Flutter app to platform-specific APIs. For documentation, see
  <https://flutter.dev/platform-channels/>.

- **Platform Channel Swift** The [platform channel swift
  app](platform_channel_swift) is the same as [platform
  channel](platform_channel) but the iOS version is in Swift and there is no
  Android version.

## Notes

Note on Gradle wrapper files in `.gitignore`:

Gradle wrapper files should normally be checked into source control. The example
projects don't do that to avoid having several copies of the wrapper binary in
the Flutter repo. Instead, the Gradle wrapper is injected by Flutter tooling,
and the wrapper files are .gitignore'd to avoid making the Flutter repository
dirty as a side effect of running the examples.
