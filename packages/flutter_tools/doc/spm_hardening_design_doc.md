# Flutter Design Doc: Hardening Swift Package Manager Integration

**Author**: Rick Hohler (suggested)
**Status**: Draft
**Created**: 2026-02-08
**Reviewers**: @vashworth (suggested), @flutter/ios-reviewers
**Tracking Issue**: [TBD]

## 1. Objective

To improve the robustness and maintainability of Flutter's Swift Package Manager (SPM) integration by replacing fragile regex-based manifest manipulation with a deterministic, model-based regeneration strategy.

## 2. Background

Flutter's initial SPM support introduced `SwiftPackageManifestManipulator`, a utility class designed to update `Package.swift` files in-place using regular expressions. This was primarily used to update the `IPHONEOS_DEPLOYMENT_TARGET` when the Flutter project's deployment target changed.

While this minimized file I/O, it has proven fragile. The `Package.swift` format is flexible, and regex-based parsing is insufficient to handle valid Swift syntax variations (comments, formatting changes, strict concurrency flags). Furthermore, patching specific lines fails to guarantee the integrity of the overall package manifest, leading to hard-to-debug build failures when the manifest state drifts from the project state.

## 3. Overview

This proposal deprecates the "patching" approach in favor of "regeneration". The `FlutterGeneratedPluginSwiftPackage` is a synthetic package owned by the Flutter tool. As such, its manifest should be treated as a derived artifact, fully regenerated from the project's source of truth (plugins + build settings) whenever a relevant change is detected.

## 4. Detailed Design

### 4.1. Core component: `SwiftPackageManager`

The key change is in `packages/flutter_tools/lib/src/macos/swift_package_manager.dart`.

**Before:**
*   `SwiftPackageManager` delegated updates to a static helper, `SwiftPackageManifestManipulator`.
*   `updateMinimumDeployment` was a static method that parsed the file on disk.

**After:**
*   `SwiftPackageManager` becomes the single source of truth.
*   `generatePluginsSwiftPackage` is refactored to accept an optional `deploymentTarget` override.
*   `updatePluginPackageDeploymentTarget` is an instance method that re-drives the generation process:
    1.  It resolves the full list of plugins.
    2.  It determines the correct deployment target (checking for overrides).
    3.  It calls `generatePluginsSwiftPackage` to completely rewrite `Package.swift`.

### 4.2. Removal of `SwiftPackageManifestManipulator`

The `packages/flutter_tools/lib/src/macos/swift_package_utils.dart` file, which contained the regex logic, is deleted. This simplifies the codebase and removes the maintenance burden of parsing Swift syntax with Dart regexes.

### 4.3. Integration Points

The build flow in `packages/flutter_tools/lib/src/ios/mac.dart` (and similarly for macOS) is updated to:
1.  Instantiate `SwiftPackageManager` early in the build process.
2.  Invoke `updatePluginPackageDeploymentTarget` when the project's deployment target is validated.

## 5. Testing Plan

### 5.1. Unit Tests
*   Refactor `swift_package_manager_test.dart` to verify that calling `updatePluginPackageDeploymentTarget` produces a binary-identical `Package.swift` to one created by a fresh `generatePluginsSwiftPackage` call.
*   Verify that custom deployment targets (e.g., passing '17.0') are correctly reflected in the platform definition line: `.iOS("17.0")`.

### 5.2. Integration Tests
*   Verify via existing integration tests that adding/removing plugins triggers a correct regeneration.
*   Verify that `flutter build ios` succeeds after manually changing the deployment target in Xcode.

## 6. Migration

No manual migration is required for users. The next time they run a build command, their `ios/Flutter/FlutterGeneratedPluginSwiftPackage/Package.swift` will be updated to the new format (if it differs). This is a strictly internal tooling change.
