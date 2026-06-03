# Bumping the Dart SDK Version Constraint

This document describes the process, policy, and instructions for bumping the minimum Dart SDK version constraint across the `flutter/flutter` repository.

For instructions on rolling the actual Dart SDK binary/compilers into the Flutter Engine, see [Rolling the Dart SDK](Rolling-Dart.md).

---

## Overview

Every Dart package in the `flutter/flutter` repository (including the `flutter` framework, `flutter_tools`, dev tools, tests, and examples) specifies a minimum Dart SDK version constraint in its `pubspec.yaml`:

```yaml
environment:
  sdk: ^3.11.0-0
```

### The `-0` Pre-release Suffix
It is important to include the `-0` pre-release suffix (e.g., `^3.13.0-0` instead of `^3.11.0`).
* **Why:** According to Dart package resolution rules, standard caret constraints (like `^3.11.0`) exclude pre-release versions of that major/minor release (e.g. `3.11.0-dev` or `3.11.0-5.0.pre`).
* Since Flutter’s `master` branch tracks Dart's active development and beta branches, developers and CI run on pre-release Dart SDKs. Omitting the `-0` suffix will cause package resolution to fail on pre-releases.

---

## Policy and Cadence

### Ownership and Cadence
The Dart SDK constraint bump process in the `flutter/flutter` repository is typically owned by `team-framework`. Bumps are usually performed quarterly, shortly after a new Dart stable version is released.

### The Stable Version Constraint Policy
The Dart SDK version constraint in `flutter/flutter` must not exceed the current Dart stable release version. Even though the `master`/`main` branch runs on newer pre-release Dart SDKs downloaded from the Engine stamp, the minimum `sdk` constraint declared in our `pubspec.yaml` files is restricted to the stable release version.

This policy is strictly enforced for two primary reasons:

1. **Stable Branch Cherry-picks:**
   Flutter frequently needs to cherry-pick bug fixes from the `main`/`master` branch into the active `stable` (or `beta`) release branches. If the code on `main`/`master` is allowed to use language features or dependencies requiring a newer Dart version than the stable SDK, cherry-picking those commits directly onto the stable branch becomes complicated.
2. **Formatting, Lints, and Migrations:**
   Upgrading the minimum Dart version often triggers new static analysis lints, deprecation warnings, or changes in code formatting (`dart format`). These updates sometimes require repo-wide refactoring or massive formatting migrations. Attempting to absorb and resolve these changes on a continuously rolling basis with unstable Dart versions is highly disruptive. Bumping quarterly to a defined stable target allows the team to manage and absorb formatting/lint sweeps predictably.

> [!IMPORTANT]
> Before planning or executing a constraint bump, the target Dart SDK version must already have rolled into the `flutter/flutter` repository via an Engine roll. If the SDK constraint in the pubspecs is bumped to a version newer than the SDK downloaded in the local cache, CI, tests, and static analysis will fail.

### New Language Features and Style Guide Updates

When a Dart SDK bump introduces new language features, they should not be adopted ad-hoc across the codebase. Instead:
1. **Style Guide Updates:** The new features should be evaluated and documented in the [Style guide for Flutter repo](../contributing/Style-guide-for-Flutter-repo.md) to define standard patterns and decide if any usage should be restricted or preferred.
2. **Organized Migration:** To maintain consistency and avoid fragmented code styles, migrations to adopt new features are usually organized as a coordinated effort. This typically involves opening a tracking issue (such as [issue #172188](https://github.com/flutter/flutter/issues/172188)) to manage and review the migration systematically.
---

## How to Bump the Dart SDK Constraint

Because the repository contains over 100 `pubspec.yaml` files (including packages, tools, manual/integration tests, and examples), the change must be made systematically.

### Step 1: Update `pubspec.yaml` Files
Update the SDK constraint in all `pubspec.yaml` files across the repository. You can use a search-and-replace command or a script to automate this:

```bash
# Example using find and sed to bump from ^3.10.0-0 to ^3.13.0-0
find . -name "pubspec.yaml" -not -path "*/.dart_tool/*" -exec sed -i '' 's/sdk: \^3.10.0-0/sdk: \^3.13.0-0/g' {} +
```

### Step 2: Force Upgrade & Update Hashes
Flutter enforces a dependency checksum at the bottom of each `pubspec.yaml`. Run the `update-packages` tool to re-solve the package workspace, generate updated `pubspec.lock` files, and update the checksums:

```bash
flutter update-packages --force-upgrade --update-hashes
```

### Step 3: Run Static Analysis & Tests
Run the repo-wide analysis script to verify the new constraints solve correctly and do not introduce any analyzer errors or lints:

```bash
dart --enable-asserts dev/bots/analyze.dart
```


Follow this by running the test suites on your target platforms to ensure no runtime regressions occur, e.g.:

```bash
flutter test packages/flutter_tools
flutter test packages/flutter
```

### Step 4: Open a Pull Request

Commit the updated `pubspec.yaml`, `pubspec.lock` files, and checksum updates, then submit a pull request.

> [!WARNING]
> If your PR breaks Google internal (Google3) integration due to unresolved Dart SDK version mismatches, it may be reverted. Coordinate with the current Flutter roll managers to ensure alignment.

