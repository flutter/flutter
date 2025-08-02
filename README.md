<a href="https://flutter.dev/">
  <h1 align="center">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://storage.googleapis.com/cms-storage-bucket/6e19fee6b47b36ca613f.png">
      <img alt="Flutter" src="https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png">
    </picture>
  </h1>
</a>

[![Flutter CI Status](https://flutter-dashboard.appspot.com/api/public/build-status-badge?repo=flutter)](https://flutter-dashboard.appspot.com/#/build?repo=flutter)
[![Discord badge]][discord instructions] [![Twitter handle]][twitter badge]
[![BlueSky badge]][bluesky handle]
[![codecov](https://codecov.io/gh/flutter/flutter/branch/master/graph/badge.svg?token=11yDrJU2M2)](https://codecov.io/gh/flutter/flutter)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/5631/badge)](https://bestpractices.coreinfrastructure.org/projects/5631)
[![SLSA 1](https://slsa.dev/images/gh-badge-level1.svg)](https://slsa.dev)

Flutter is Google's SDK for crafting beautiful, fast user experiences for
mobile, web, and desktop from a single codebase. Flutter works with existing
code, is used by developers and organizations around the world, and is free and
open source.

## Documentation

- [Install Flutter](https://flutter.dev/get-started/)
- [Flutter documentation](https://docs.flutter.dev/)
- [Development wiki](./docs/README.md)
- [Contributing to Flutter](https://github.com/flutter/flutter/blob/main/CONTRIBUTING.md)

For announcements about new releases, follow the
[flutter-announce@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-announce)
mailing list. Our documentation also tracks
[breaking changes](https://docs.flutter.dev/release/breaking-changes) across
releases.

## Terms of service

The Flutter tool may occasionally download resources from Google servers. By
downloading or using the Flutter SDK, you agree to the Google Terms of Service:
https://policies.google.com/terms

For example, when installed from GitHub (as opposed to from a prepackaged
archive), the Flutter tool will download the Dart SDK from Google servers
immediately when first run, as it is used to execute the `flutter` tool itself.
This will also occur when Flutter is upgraded (e.g. by running the
`flutter upgrade` command).

## About Flutter

We think Flutter will help you create beautiful, fast apps, with a productive,
extensible and open development model, whether you're targeting iOS or Android,
web, Windows, macOS, Linux or embedding it as the UI toolkit for a platform of
your choice.

### Beautiful user experiences

We want to enable designers to deliver their full creative vision without being
forced to water it down due to limitations of the underlying framework.
Flutter's [layered architecture] gives you control over every pixel on the
screen and its powerful compositing capabilities let you overlay and animate
graphics, video, text, and controls without limitation. Flutter includes a full
[set of widgets][widget catalog] that deliver pixel-perfect experiences whether
you're building for iOS ([Cupertino]) or other platforms ([Material]), along
with support for customizing or creating entirely new visual components.

<p align="center"><img src="https://github.com/flutter/website/blob/main/src/content/assets/images/docs/homepage/reflectly-hero-600px.png?raw=true" alt="Reflectly hero image"></p>

### Fast results

Flutter is fast. It's powered by hardware-accelerated 2D graphics libraries like
[Skia] (which underpins Chrome and Android) and [Impeller]. We architected
Flutter to support glitch-free, jank-free graphics at the native speed of your
device.

Flutter code is powered by the world-class [Dart platform], which enables
compilation to 32-bit and 64-bit ARM machine code for iOS and Android,
JavaScript and WebAssembly for the web, as well as Intel x64 and ARM for desktop
devices.

<p align="center"><img src="https://github.com/flutter/website/blob/main/src/content/assets/images/docs/homepage/dart-diagram-small.png?raw=true" alt="Dart diagram"></p>

### Productive development

Flutter offers [stateful hot reload][hot reload], allowing you to make changes
to your code and see the results instantly without restarting your app or losing
its state.

[![Hot reload animation]][hot reload]

### Extensible and open model

Flutter works with any development tool (or none at all), and also includes
editor plug-ins for both [Visual Studio Code] and [IntelliJ / Android Studio].
Flutter provides [tens of thousands of packages][flutter packages] to speed your
development, regardless of your target platform. And accessing other native code
is easy, with support for both FFI ([on Android][android ffi],
[on iOS][ios ffi], [on macOS][macos ffi], and [on Windows][windows ffi]) as well
as [platform-specific APIs][platform channels].

Flutter is a fully open-source project, and we welcome contributions.
Information on how to get started can be found in our
[contributor guide](CONTRIBUTING.md).

[android ffi]: https://docs.flutter.dev/development/platform-integration/android/c-interop
[bluesky badge]: https://img.shields.io/badge/Bluesky-0285FF?logo=bluesky&logoColor=fff&label=Follow%20me%20on&color=0285FF
[bluesky handle]: https://bsky.app/profile/flutter.dev
[cupertino]: https://docs.flutter.dev/development/ui/widgets/cupertino
[dart platform]: https://dart.dev/
[discord badge]: https://img.shields.io/discord/608014603317936148?logo=discord
[discord instructions]: ./docs/contributing/Chat.md
[flutter packages]: https://pub.dev/flutter
[hot reload]: https://docs.flutter.dev/development/tools/hot-reload
[hot reload animation]: https://github.com/flutter/website/blob/main/src/content/assets/images/docs/tools/android-studio/hot-reload.gif?raw=true
[impeller]: https://docs.flutter.dev/perf/impeller
[intellij / android studio]: https://plugins.jetbrains.com/plugin/9212-flutter
[ios ffi]: https://docs.flutter.dev/development/platform-integration/ios/c-interop
[layered architecture]: https://docs.flutter.dev/resources/inside-flutter
[macos ffi]: https://docs.flutter.dev/development/platform-integration/macos/c-interop
[material]: https://docs.flutter.dev/development/ui/widgets/material
[platform channels]: https://docs.flutter.dev/development/platform-integration/platform-channels
[skia]: https://skia.org/
[twitter badge]: https://twitter.com/intent/follow?screen_name=flutterdev
[twitter handle]: https://img.shields.io/twitter/follow/flutterdev.svg?style=social&label=Follow
[visual studio code]: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
[widget catalog]: https://flutter.dev/widgets/
[windows ffi]: https://docs.flutter.dev/development/platform-integration/windows/building#integrating-with-windows
