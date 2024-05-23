This page contains old annual roadmaps, which are provided for historical context.

# 2023

This roadmap is aspirational; it represents some of what our most active contributors to Flutter have told us they plan to work on this year. It is in general difficult to make any guarantees about engineering work, and it is all the more so for an open source project with hundreds of contributors.

_Our [Flutter Forward keynote](https://flutter.dev/events/flutter-forward) demoed some of these future plans!_

## Technical debt and team velocity

As always, the most important work we can do is increasing the overall velocity of the project. This includes reducing technical debt like flaky tests, but it also means improving our processes to help new people join the team and be productive faster. To this end, we will be starting a regular meeting for team members where velocity issues can be raised, documented, and addressed. Meetings are announced to team members on our Discord using the Discord Events feature.

Depending on the economic and epidemiological climates, we may also organize a summit to bring the team together.

We also plan to spend some time this year going through our issue backlog, closing issues that are obsolete or not actionable, and prioritizing the remaining issues.

## Performance

Our top priority for Flutter improvements this year is performance.

We want to completely [remove shader compiler jank](https://github.com/orgs/flutter/projects/21), first on iOS and then on Android and desktop.

For web, we are working on [supporting Wasm as a target](https://github.com/flutter/flutter/issues/41062), and have plans to investigate the use of [multi-threaded rendering](https://github.com/flutter/flutter/issues/114243), reduce the download size for a basic Flutter application, and improve the performance of custom shaders.

For our VM-based backends, we are looking to make [improvements to our memory allocation strategy](https://github.com/dart-lang/sdk/issues/47574) to improve responsiveness and app startup performance.

## Quality

Accessibility is critical to Flutter applications, and we will continue to invest heavily in making it easy for Flutter applications to be accessible, improving the quality of our accessibility support on all our platforms. Similarly, it is important to us to continue to improve our documentation. In both cases, the improvements are largely expected to be in the form of bug fixes and small patches, rather than large projects that are easy to describe on a roadmap, but that does not make them any less important.

We will also continue to implement features needed for full fidelity on each platform, especially the fast-moving Android and iOS. For example, we expect to make significant progress on our Cupertino widget set this year, bringing it up to date and growing the number of supported widgets, and we plan to implement support for [Android's predictive back gesture](https://github.com/flutter/flutter/issues/109513) and [Android handwriting input](https://github.com/flutter/flutter/issues/115607). We also plan to port the [camera plugin](https://github.com/flutter/packages/tree/main/packages/camera) to Android's latest CameraX APIs.

## Security

We will continue to work on [SLSA compliance](https://slsa.dev/) (supply chain integrity), with a goal to reach SLSA-3 for our main repositories this year, with an eye to continue to SLSA-4 next year. We also want to extend our tooling to enable Flutter package and application developers to achieve the same level of security.

## Features

We do expect to spend some time on a few new features. These are generally driven by one of three motivations: popularity (we look at how many "thumbs-up" reactions an issue has received to help prioritize efforts), parity and portability (once one platform supports a feature, we feel it is important to make it work everywhere), and supporting some other effort (e.g. a new feature that can enable further performance improvements).

The most notable features we expect to implement this year are:

* [Custom asset transformers](https://github.com/flutter/flutter/issues/101077), because they enable some performance improvements.
* [Efficient 2D scrolling widgets](https://github.com/orgs/flutter/projects/32) (e.g. [tables](https://github.com/flutter/flutter/issues/87370) and [trees](https://github.com/flutter/flutter/issues/114299)), to improve the performance of applications with this kind of interface.
* [Multiple windows](https://github.com/flutter/flutter/issues/30701), especially for desktop platforms, because this is a very highly requested feature.
* Platform Views on [macOS](https://github.com/flutter/flutter/issues/41722) and [Windows](https://github.com/flutter/flutter/issues/108486), by popular demand.
* [Drag and drop](https://github.com/flutter/flutter/issues/30719), also by popular demand.
* [Wireless debugging on iOS](https://github.com/flutter/flutter/issues/15072), our second-most-requested feature.
* [Custom "flutter create" templates](https://github.com/flutter/flutter/issues/77104), which makes it much easier for third-parties (e.g. [the Flame engine](https://flame-engine.org/)) to bootstrap developers.
* Supporting [element embedding](https://github.com/flutter/flutter/issues/118481) (see also [#32329](https://github.com/flutter/flutter/issues/32329)), which allows Flutter content to be added to any standard web &lt;div>, by popular demand.

## Research

A lot of developers have expressed an interest in creating applications that integrate closely with the look and feel of their target platform, while supporting multiple platforms, without having to reimplement their interface multiple times. We want to study whether some form of adaptive layout would be able to address these needs, starting with Android vs iOS.

With our new graphics backend comes the opportunity for new features, and one in particular that we are interested in studying more closely is the integration of 3D into Flutter scenes. We expect to begin experiments with 3D this year. Similarly, we believe our new graphics backend may enable improvements to the low-level dart:ui API, and new shader features.

Relatedly, we are investigating implementing [wide color gamut support](https://github.com/flutter/flutter/issues/55092) (probably starting with iOS), as it is a highly requested feature.

We are also actively investigating migrating from ICU4C to ICU4X (the new [Rust-based ICU backend](https://github.com/unicode-org/icu4x)), which will require research into how to embed Rust into our build pipeline across all our platforms, how to share Rust code between our engine and Dart FFI packages, and how to perform tree-shaking for binary code used in such packages.

Finally, we expect to spend some time investigating how to update Flutter to take advantage of new features coming from Dart this year, such as updating our APIs to make use of records and patterns, updating our toolchain to support RISC-V, or making use of new FFI features for plugins.

## Releases

We plan to have four stable releases and 12 beta releases during 2023. In 2023 we will probably move to announcing new features when they reach the beta channel rather than waiting for them to be on the stable release channel. In general we encourage people looking for a faster update cycle to use the beta channel.

## Non-goals

We unfortunately have had to shelve our current efforts to implement hot reload on web, as our web compiler experts are all working on Wasm production support. We also have no plans currently to implement [code push](https://github.com/flutter/flutter/issues/14330#issuecomment-1279484739), built-in support for wearables ([Apple Watch](https://github.com/flutter/flutter/issues/28901#issuecomment-1385926218), [Android Wear](https://github.com/flutter/flutter/issues/2057)) or [automotive integrations](https://github.com/flutter/flutter/issues/26801#issuecomment-1013565542), built-in support for [SEO on web](https://github.com/flutter/flutter/issues/46789#issuecomment-1007835929), or [installation via homebrew](https://github.com/flutter/flutter/issues/14050#issuecomment-1012647917). (Some of these have excellent packages available though.)

In general we prioritize [issues with the most thumbs-up reactions on GitHub](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc), and the astute among you may notice that the list of non-goals includes a number of these highest-rated issues. Unfortunately, we have discovered a pattern that we did not expect, though it is obvious in retrospect: when we address all the highest-ranked issues except for those that are technically infeasible or intractable for whatever reason, the result is that the highest-ranked issues that are left are _all_ issues that are infeasible or somehow intractable.

_See also: [Popular issues](../contributing/issue_hygiene/Popular-issues.md), which discusses each of the top 10 issues._


# 2022

_You may also be interested in [Google's discussion of its strategy for Flutter in 2022](https://medium.com/flutter/flutter-in-2022-strategy-and-roadmap-8c5eaf7c4275)._

## Areas of Focus

### Developer experience

The area where we will spend most of our focus is the developer experience. It is our intent to create an SDK that developers love. This will manifest in a myriad of different areas, for example creating widgets or plugins that solve common scenarios, cleaning up existing APIs, introducing new APIs to simplify frequently-seen patterns, improving error messages, evolving our developer tools and IDE plugins, creating new lints, fixing bugs in the framework and engine, improving API documentation, creating more useful samples, hot reload on the web, and improving stack traces in Dart-to-JS scenarios.

### Desktop

In 2022 we plan to bring our desktop support to the stable channel. We plan on focusing on testing and announcing one platform at a time, as they become ready, starting with [Windows](https://github.com/flutter/flutter/projects/209), then [Linux](https://github.com/flutter/flutter/projects/216), and [macOS](https://github.com/flutter/flutter/projects/215). A significant part of this effort is expanding our regression test suite to give us the confidence that enables us to expand on these efforts without breaking existing code.

### Web

Regarding Flutter for web in particular, we plan to work on improving performance, plugin quality, accessibility, and consistency across browsers. We also intend to make it much easier to embed Flutter applications inside other, non-Flutter, HTML pages.

### Framework and engine

We will update the Material library to [support Material 3](https://github.com/flutter/flutter/issues/91605). This is primarily motivated by our goal to improve fidelity with Android, though it is not limited to that platform.
We intend to implement cross-widget text selection. This is motivated by our goal of achieving good fidelity with the web platform, though again it is not limited to the web.

We intend to improve the text editing experience on various platforms, for example improving our fidelity with desktop text editing conventions and our integration with iPadOS handwriting recognition.

For desktop and web we will provide a solution for menus (context menus and menu bars), including integration with the host OS (which is particularly relevant for macOS).

Finally, also motivated by desktop though again not limited just to that platform, we intend to experiment with supporting rendering to multiple windows from a single Isolate.

### Dart

We plan to continue to evolve the language at a deliberately slow but steady pace. We expect to introduce one major feature in 2022 (probably static metaprogramming; we will make decisions based on our confidence that the feature will improve the language), as well as some minor language improvements, probably including improving the import syntax for packages.

We also plan to expand Dart's compilation toolchain to support compiling to Wasm, contingent on the timely standardisation of WasmGC.

### Jank

[In 2021](https://docs.google.com/presentation/d/1QbNm5Z4JyZLd6czVEL3jlgeR7R_ENgXlnm64n2Z40ss/edit) we resolved a number of issues around jank, but our conclusion was that we needed to entirely rethink how we used shaders. As a result, we have been rewriting our graphics backend. In 2022, we intend to migrate Flutter on iOS to this new architecture, and then, based on our experience with this, begin work on porting this solution to other platforms. In addition, we will also implement other performance improvements and performance introspection features, such as those which our new [DisplayList](https://github.com/flutter/flutter/issues/85737) system has made possible.

## Planned deprecations

We plan to [drop support for 32bit iOS](https://flutter.dev/go/rfc-32-bit-ios-support) in 2022.

## Infrastructure

In 2022 we will increase our investment in supply chain security, with the intent to eventually bring our infrastructure in line with the requirements described in [SLSA level 4](https://slsa.dev/spec/).

***

# 2021

## Areas of Focus

### Null safety

We will be introducing [Dart's sound null safety](https://dart.dev/null-safety) to Flutter, and shepherding the migration of the plugin and package ecosystem to null safety, including migrating the packages and plugins directly maintained by the Flutter team.

As part of this we plan to provide a migration tool, samples, and documentation to aid migration of existing code.

### Android and iOS

We are continuing to address [jank-on-startup performance issues](https://github.com/flutter/flutter/projects/188).

We will work on supporting incremental downloads of assets and code from the stores (subject to each platform's limitations), allowing the initial download of applications to be much smaller than the full download, with data fetched on demand.

We will also seek to improve the performance and ergonomics, and reduce the overhead, of embedding Flutter in existing applications on Android and iOS.

In addition, as usual, we plan to add support for new features of the iOS and Android operating systems.

### Web and Desktop

Our goal for 2021 is to deliver production-quality support for Web, macOS, Windows and Linux, in addition to iOS and Android, enabling developers to create apps across six separate platforms using the same SDK.

For Web specifically, our focus will be on fidelity and performance, rather than new features, as we drive to prove that Flutter can provide a high quality experience on the Web.

For desktop, in addition to ensuring a quality experience, we will also be completing our work on the accessibility layer, and adding support for showing multiple independent windows.

### Improving the developer experience

We will continue to focus on removing friction points. One area of research will be around reducing the boilerplate needed to achieve common goals in Flutter. We will also build on our investment in migration tooling for null safety to investigate the possibility of creating tooling that enables us to make breaking changes easier for developers to manage, which would enable us to make some long-desired improvements to our APIs that we have so far avoided due to their breaking nature.

### Ecosystem

In 2021, we will continue to work with the community on the Flutter-team-supported plugins. The goal will be to bring the pre-release plugins up to production quality and maintain them at that level by being increasingly responsive to issues and PRs.
We also plan specifically to make significant improvements to the WebView plugin.

### Quality

We will have efforts around improving Flutter’s memory usage, application download size overhead, runtime performance, battery usage, and jank, based on experiences with real Flutter-based applications. These may take the form of engine or framework fixes, as well as documentation or videos describing best practices. We also intend to improve our tooling to help debug issues around memory usage.

In addition, we will continue to address bug reports. In 2020, we [resolved](https://github.com/issues?q=is%3Aissue+closed%3A2020+is%3Aclosed+user%3Aflutter) over 17,000 issues during the year, and our goal is to have at least that level of impact in 2021.

### New features

While in 2020 we primarily focused on fixing bugs, in 2021 we plan to also add significant new features. Some are listed above. We also intend to make improvements to our table widgets and introduce some tree widgets, with support for large numbers of columns, rows and/or tree levels, and column- or row-spanning cells.

## Release Channels and Cadence

Flutter offers three “channels” from which developers can receive updates: master, beta and stable, with increasing levels of stability and confidence of quality but longer lead times for changes to propagate. We plan to release one beta build each month, typically near the start of the month, and about four stable releases throughout the year. We recommend that you use the stable channel for apps released to end-users. For more details on our release process, see the [Flutter build release channels](../releases/Flutter-build-release-channels.md) wiki page.

We used to also have a _dev_ channel which represented a level of stability between master and beta. At the end of 2021, we retired this channel; it is no longer updated.

***

# 2020

## Areas of focus

### Web and Desktop

At our Flutter Interact event in December 2019, we announced that our support for Web had progressed to beta-level quality. We intend to continue this work with the goal of having Web be supported as an equal peer to Android and iOS. We hope to similarly continue our work in making Flutter the best way to create desktop applications.

Our goal for this year is that you should be able to run `flutter create; flutter run` and have your application run on Web browsers, macOS, Windows, Android, Fuchsia, and iOS, with support for hot reload, plugins, testing, and release mode builds. We intend to ensure that our Material Design widget library works well on all these platforms.

_We don't intend to provide desktop-equivalents of the Cupertino widget library in 2020._

### Quality

Our other main goal is to improve Flutter's quality, fixing bugs and addressing a few of the most-highly requested features. This covers a wide range of areas but we have a particular focus on our Cupertino library and iOS fidelity, our support for the long tail of Android devices, and the development experience.

We intend to deliver on long-anticipated features such as our router refactor, instance state saving and restoring, and an improved internationalization workflow.

In general in 2020 we intend to primarily focus on fixing bugs rather than adding new features.

_We mainly use the "Thumbs-Up" emoji reactions on the first comment of an issue to determine its importance. See the [Issue hygiene](../contributing/issue_hygiene/README.md) wiki page for more details on our prioritization strategy._
