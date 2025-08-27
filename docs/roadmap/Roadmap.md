In the interest of transparency, we want to share high-level details of our roadmap so that others can see our priorities and make plans based off the work we are doing.

Our plans will evolve over time based on customer feedback and new market opportunities. We will use our surveys and feedback on GitHub issues to prioritize work. The list here shouldn't be viewed either as exhaustive nor a promise that we will complete all this work. If you have feedback about what you think we should work on, we encourage you to get in touch by [filing an issue](https://github.com/flutter/flutter/issues/new/choose), or using the "thumbs-up" emoji reaction on an issue's first comment. Because Flutter is an open source project, we invite contributions both towards the themes presented below and in other areas.

_If you are a contributor or team of contributors with long-term plans for [contributing to Flutter](../../CONTRIBUTING.md), and would like your planned efforts reflected in the roadmap, please reach via email to `roadmap-input@flutter.dev`._

# 2025

This roadmap is aspirational. It represents primarily content gathered from those of us who work on Flutter as employees of Google. By now non-Google contributors outnumber those employed by Google, so this is not an exhaustive list of all the new and exciting things that we hope will come to Flutter this year!
As aways in the software business it can be difficult to accurately forecast engineering work — even more so for an open source project. So please be mindful that what we cover here is a statement of intent and not a guarantee.

## Accessibility
In 2024 we completed validation of several key use cases for accessibility on mobile platforms (iOS and Android). In 2025 we plan to focus on further accessibility support for the web platform.

## Performance
We continue to focus on quality and performance with Impeller. We plan on completing the iOS migration to Impeller by removing the Skia backend on iOS. On Android our focus is on modern Android devices, specifically those that support Android API-level 29 or later, where we expect to make Impeller the default. We saw issues in 2024 on older devices, and for now, we expect to keep Skia supported on those devices.

## Mobile (Android and iOS) platform
We'll continue to update iOS with support for the upcoming iOS 19 & Xcode 17 releases, and by completing support for Swift Package Manager (SwiftPM). We expect to make SwiftPM the default option later in 2025.

Second, we continue to refine our Cupertino support — the widgets that align with Apple's Human Interface Guidelines.

On Android, we'll investigate some of the primary features supported by the upcoming Android 16 release. We also hope to move the Gradle build logic from Groovy to Kotlin and to increase unit test coverage for build tooling.

On both iOS and Android, interoperability is critical to interface with platform-native code. We expect to continue our experimental work to support calling directly from Dart into Objective C & Swift code (for iOS) and into Java and Kotlin (for Android). This also includes calling APIs that can only be invoked on the main OS/platform thread.

## Web platform
In 2024 we made strong progress on performance and quality (such as app size reduction, and better use of multi-threading and improved app load times).

In 2025 we plan further improvements in the core of Flutter web. This includes accessibility, text input, international text rendering, size, performance, and platform integration. We also want to continue to  improve Web performance using compilation to Wasm/WebAssembly.

The new JS interop mechanism for Dart that supports both JS and Wasm compilation is complete. Next, we plan on removing the legacy HTML and JS libraries in 2025 (see breaking change announcement).

Finally, we've made good progress on support for hot reload on the web and hope to launch it in 2025.

## Desktop platform
Google's Flutter team will focus on mobile and web support in 2025 while Canonical's Flutter team continues to invest in desktop platforms such as Windows, macOS, and Linux.

In 2024, we landed multi-view rendering on desktop. In 2025, Canonical plans further improvements to multi-window support for accessibility, keyboard, text input, and focus. Canonical also plans to make progress on windowing APIs.

## Core framework

We're investigating a number of changes with a goal of reducing unnecessary verbosity in Flutter widget code.

## Tooling and AI
We'll continue to integrate with AI solutions to offer AI assistance for core programming tasks.

We'll continue to invest in our suite of tooling, which includes Flutter DevTools, VS Code, Android Studio/IntelliJ, and IDX. Additionally, we'll keep working towards always improving the edit-refresh cycle and the overall developer experience.

## Dart programming language
In 2024 we concluded that supporting macros in Dart was not viable. Based on that, in 2025 we expect to improve the current support for code generation in build_runner, and to investigate alternatives ways of improving Dart support for serialization and deserialization.

We also expect to ship one or more language features currently going through the Dart language design funnel.

## Dart compilers and tools
We plan to refactor the Dart analyzer and the front-end compiler to share more of their implementations so that this can accelerate future language feature development, performance, and stability.

We also plan on investigating support for cross-compiling Dart AOT executables (for example, compiling to a Linux AOT executable on a macOS development machine).

## Releases
We plan to have four stable releases and 12 beta releases during 2025, similar to 2024. To improve the predictability and regularity of these releases, and to reduce regressions in stable releases, we'll invest in further test coverage.

We'll also make investments to improve our ability to expedite the release of any needed hotfix/patch  releases.

## Non-goals
We're still not planning on investing in built-in support for code push or hot updates. For code push, our friends at shorebird.dev may have offerings of interest. For UI push (also known as server-driven UI), we recommend the rfw package.

We're also not planning on adding any additional supported platforms.




***

_We maintain an [archive of roadmaps from previous years]([Archive]-Old-Roadmaps.md) in a separate page._
