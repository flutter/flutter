# Removing support for an Android API level in Flutter (go/flutter-android-remove-api-level)

## Objective

Provides a list of areas to consider and examples of former work for how to update Flutter to no longer support an old version of the Android API.

### Overview
After Flutter has decided to bump the minimum supported Android SDK, ideally through a justification document like http://goto.google.com/rfc-flutter-android-m-deprecation, this document covers what to update and suggests an order.

#### Google3
Googlers should start by following the Google3 migration steps defined in go/flutter-android-g3-minsdk-version.
Google apps can be migrated to a higher minimum API level before Flutter drops support.

#### Bump templates used in `flutter create`
Templates take the least justification or configuration to bump.
Example PR: https://github.com/flutter/flutter/pull/170882

#### Add auto migration for apps targeting deprecated APIs.

Example PR: https://github.com/flutter/flutter/pull/170882 `android_project_migration_test.dart`

#### Modify tooling to enforce a new minimum version.

Example PR: https://github.com/flutter/flutter/pull/170882 see `DependencyVersionChecker.kt` and `gradle_utils.dart`

#### Update the engine minSdk and tests
[Upgrading-Engine's-Android-API-version.md](Upgrading-Engine's-Android-API-version.md)

#### Breaking change notice
Create a breaking change notice for the next stable release.

See "Minimum Android SDK has changed" in [Flutter 3.35 Technical Blog Post](https://blog.flutter.dev/whats-new-in-flutter-3-35-c58ef72e3766).

#### Update documentation

Update documentation page to indicate the old API is not tested: https://docs.flutter.dev/reference/supported-platforms.

Example PR: https://github.com/flutter/website/pull/12230

##### Issue hygiene
Close all GitHub issues against the deprecated platform.

#### Packages
After a stable build is published with the new minimum Android API level.

1. Update all existing Flutter maintained plugins to use the new stable Flutter version.
2. Audit native Android code in any plugins that have no longer used codepaths and delete those codepaths.

Example PRs:
* https://github.com/flutter/packages/pull/9851
* https://github.com/flutter/packages/pull/9987
* https://github.com/flutter/packages/pull/10470


#### Related documents

Example tracking bug for `minSdk` 24 https://github.com/flutter/flutter/issues/170807
Google3 documentation go/flutter-android-g3-minsdk-version
