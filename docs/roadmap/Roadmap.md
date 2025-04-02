In the interest of transparency, we want to share high-level details of our roadmap, so that others can see our priorities and make plans based off the work we are doing.

Our plans will evolve over time based on customer feedback and new market opportunities. We use our surveys and feedback on GitHub issues to prioritize work. The list here shouldn't be viewed either as exhaustive, nor a promise that we will complete all this work. If you have feedback about what you think we should be working on, we encourage you to get in touch (e.g. by [filing an issue](https://github.com/flutter/flutter/issues/new/choose), or using the "thumbs-up" emoji reaction on an issue's first comment). Flutter is an open source project, we invite contributions both towards the themes presented below and in other areas.

_If you are a contributor or team of contributors with long-term plans for [contributing to Flutter](../../CONTRIBUTING.md), and would like your planned efforts reflected in the roadmap, please reach out to Hixie (ian@hixie.ch)._

# 2025

This roadmap is, as always, aspirational. It represents primarily content gathered from those of us who work on Flutter as employees of Google. By now non-Google contributors outnumber those employed by Google, so this is not an exhaustive list of all the new and exciting things that we hope will come to Flutter this year!
As aways in the software business it can be difficult to accurately forecast engineering work — even more so for an open source project. So please be mindful that what we cover here is a statement of intent, and not a gurantees that the mentioned work will be completed.

## Accessibility
In 2024 we completed validation of several key use cases for accessibility on the mobile platforms (iOS and Android). In 2025 we plan to focus on further accessibility support for the web platform.

## Performance
We continue to focus on quality and performance with Impeller.  We plan on completing the iOS migration to Impeller by removing the Skia backend on iOS. On Android our focus is on modern Android devices, specifically those that support Android API-level 29 or later, where we expect to make Impeller the default. We saw issues in 2024 on older devices, and for now, we expect to keep Skia supported on those devices.

## Mobile (Android and iOS) platform
We'll continue to update iOS with support for the upcoming iOS 19 & Xcode 17 releases, and by completing support for Swift Package Manager (SwiftPM). We expect to make SwiftPM the default option later in 2025.

Second, we continue to refine our Cupertino support — the widgets that align with Apple's Human Interface Guidelines.

On Android, we'll investigate some of the primary features supported by the upcoming Android 16 release. We also have the goal of moving Gradle build logic from Groovy to Kotlin, and to increase unit test coverage for build tooling.

On both iOS and Android, interoperability is critical to interface with platform-native code. We expect to continue our experimental work to support calling directly from Dart into Objective C & Swift code (for iOS) and into Java and Kotlin (for Android). This also includes calling APIs that can only be invoked on the main OS/platform thread.

## Web platform
In 2024 we made strong progress on performance and quality (such as app size reduction, and better use of multi-threading and improved app load times).

In 2025 we plan further improvements in the core of Flutter web, for example: accessibility, text input, international text rendering, size, performance, and platform integration. We also continue to work on improving Web performance using compilation to Wasm/WebAssembly.

The new JS interop mechanism for Dart that supports both JS and Wasm compilation is considered complete. With that, in 2025 we plan on removing the legacy HTML and JS libraries (see breaking change announcement).

Finally, we've made good progress on support for hot reload on the web, and hope to launch it in 2025.

## Desktop platform
Google's Flutter team will focus on mobile and web support in 2025. However, Canonical's Flutter team continues to invest in desktop platforms (Windows, macOS, and Linux).

In 2024, we landed multi-view rendering on desktop. In 2025, Canonical plans further improvements to multi-window, such as accessibility, keyboard, text input, and focus support. Canonical also plans to make progress on windowing APIs.

## Tooling and AI
We'll continue integrate with AI solutions to offer AI assistance for core programming tasks.

We'll continue to invest in our suite of tooling including Flutter DevTools, VS Code, Android Studio/IntelliJ, as well as IDX, with an eye toward always improving the edit-refresh cycle and the overall developer experience.

## Dart programming language
In 2024 we concluded that supporting macros in Dart was not viable. Based on that, in 2025 we expect to improve the current support for code generation in build_runner, and to investigate alternatives ways of improving Dart support for serialization and deserialization.

We also expect to ship one or more language features currently going through the Dart language design funnel.

## Dart compilers and tools
We'll work on refactoring the Dart analyzer and the front-end compiler to share more of their implementations, with the goal of accellerating future language feature development, and to make them more performant and stable.

We also plan on investigating support for cross-compiling Dart AOT executables (for example, compiling to a Linux AOT executable on a macOS development machine).

## Releases
We plan to have four stable releases and 12 beta releases during 2025, similar to 2024. To improve the predictability and regularity of these releases, and to reduce regressions in stable releases, we'll invest in further test coverage.

We'll also make investments to improve our ability to expedite the release of any needed hotfix/patch  releases.

## Non-goals
We're still not planning on investing in built-in support for code push or hot updates. For code push, our friends at shorebird.dev may have offerings of interest. For UI push (also known as server-driven UI), we recommend the rfw package.

We're also not planning on adding any additional supported platforms.


# 2024

This roadmap is aspirational; it represents some of what our most active contributors to Flutter and Dart have told us they plan to work on this year. It is in general difficult to make any guarantees about engineering work, and it is all the more so for an open source project with hundreds of contributors.

## Core framework & engine

We continue to focus on quality and performance with Impeller.  We plan on completing the iOS migration to Impeller by removing the Skia backend on iOS. On Android we expect that Impeller will support Vulkan and OpenGLES; in the near term, we will also have an opt-out to use Skia instead. Additionally, we would like to improve Impeller testing infrastructure to reduce regressions in production.

For the core framework we expect to complete the effort to fully support Material 3. We're also investigating options to generalize the core framework to better support the adaptations needed to meet design expectations on Apple devices, such as app bars and tab bars.

Work is also expected to continue on [blankcanvas](https://docs.google.com/document/d/1rS_RO2DQ_d4_roc3taAB6vXFjv7-9hJP7pyZ9NhPOdA/edit?resourcekey=0-VBzTPoqLwsruo0j9dokuOg).

## Mobile (Android and iOS) platforms

In 2023 we started an initiative to support multiple Flutter views — in 2024 our plan is to extend this support to Android and iOS. We're also working on improving the performance and test coverage/testability of platform views.

We'll continue to modernize iOS offerings by enabling/supporting latest Apple standards, such as the [privacy manifests](https://github.com/flutter/flutter/issues/143232) and [Swift Package Manager](https://github.com/flutter/flutter/issues/33850). We'll also investigate needed support for future Android releases.

On Android we'll look into supporting Kotlin in Android build files.

Interop is important to interface with native code from Dart. We expect to complete the work to support [invoking Objective C](https://dart.dev/interop/objective-c-interop) code directly from Dart, and we'll investigate support to invoke Swift code directly. Likewise for Android, we'll continue work on the support to [call into Java and Android](https://dart.dev/interop/java-interop). We'll also look into better support for calling APIs that might only be invoked on the main OS/platform thread.

We're seeing an increasing trend that larger Flutter apps often start as hybrid apps (an app that contains both Flutter code and some Android/iOS platform code/UI). We'll look into how we can better support this, both in terms of performance/overhead and developer ergonomics.

## Web platform

We'll continue to focus on performance and quality, including investigating reducing the overall application size, better use of multi-threading, supporting platform views, improving app load times, making CanvasKit the default renderer, improving text input, and investigating options for supporting [SEO for Flutter web](https://github.com/flutter/flutter/issues/46789).

We expect to complete the effort to compile Dart to WasmGC, and with that support [Wasm compilation of Flutter web apps](https://docs.flutter.dev/platform-integration/web/wasm). This also includes a [new JS interop](https://github.com/dart-lang/sdk/issues/35084) mechanism for Dart that supports both JS and Wasm compilation.

We also plan to resume work to support [hot reload on the web](https://github.com/flutter/flutter/issues/53041).

## Desktop platforms

While we expect the majority of our time to be spent on mobile and web platforms (as discussed above), we are still planning some advancements on desktop platforms:

* We're hoping to make progress on supporting platform views [on macOS](https://github.com/flutter/flutter/issues/41722) and [Windows](https://github.com/flutter/flutter/issues/31713), and with that enable support for things like webview.
* On Linux, our focus will be on GTK4 support and accessibility.
* On all platforms we will continue our work on supporting multiple views from one Dart isolate, with the eventual goal of supporting multiple windows rendering from one widget tree.

## Ecosystem

We're planning on collaborating with AI frameworks to support a new era of AI powered Flutter apps.

We are not planning on expanding the set of [flutter.dev plugins](https://pub.dev/publishers/flutter.dev/packages) we maintain, but will rather focus on raising the quality of the existing plugins, and resolving core feature gaps (for example, investigating an updated [shared_preferences](https://pub.dev/packages/shared_preferences) API that better supports use of isolates and to add-to-app use case). We'll also support community initiatives like [Flutter Favorites](https://pub.dev/packages?q=is%3Aflutter-favorite).

We'll also continue to add support for building casual games with Flutter, as a joint effort with the [Flame](https://flame-engine.org/) community.

## Tooling and AI

We hope to integrate with AI solutions to offer AI assistance for core programming tasks.

We'll also continue to collaborate with Google's [IDX team](https://developers.google.com/idx), and explore integration with design tools.

## Programming language

The Dart team expects to complete the assessment of the viability of supporting [macros](https://github.com/dart-lang/language/issues/1482) in Dart, and in 2024 either ship the first phases of supporting them, or if we discover unmitigable architectural issues, abandon the effort. Key use cases for macros include serialization/deserialization, data classes, and general extensibility.

We'll investigate a number of more incremental language features, such as syntax changes to reduce verbosity (for example, [primary constructors](https://github.com/dart-lang/language/issues/2364) and [import syntax shorthand](https://github.com/dart-lang/language/issues/649)), and better support for statically checked variance.

Finally, we'll look into re-use of Dart business logic in more places, and more pluggability/extensibility for Dart (for example, in DevTools and Analyzer).

## Releases

We plan to have four stable releases and 12 beta releases during 2024, similar to 2023.

## Non-goals

We're still not planning on investing in built-in support for [code push or hot updates](https://github.com/flutter/flutter/issues/14330). For code push, our friends at [shorebird.dev](https://shorebird.dev/) may have offerings of interest. For UI push (also known as server-driven UI), we recommend the [rfw](https://pub.dev/packages/rfw) package.

***

_We maintain an [archive of roadmaps from previous years]([Archive]-Old-Roadmaps.md) in a separate page._
