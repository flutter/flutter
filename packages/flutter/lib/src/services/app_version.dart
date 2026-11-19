// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The build name this application was built with.
///
/// This is the part of the `version` field in the app's `pubspec.yaml` before
/// the `+` separator (for example `1.2.3` for `version: 1.2.3+45`), or the
/// value of the `--build-name` option if it was provided at build time.
///
/// Unlike runtime lookups (such as reading `version.json` over the network on
/// the web), this constant is embedded in the compiled application itself, so
/// it always describes the code that is actually running.
///
/// This will be `null` if the pubspec has no `version` field and no
/// `--build-name` option was provided.
const String? appBuildName = bool.hasEnvironment('FLUTTER_BUILD_NAME')
    ? String.fromEnvironment('FLUTTER_BUILD_NAME')
    : null;

/// The build number this application was built with.
///
/// This is the part of the `version` field in the app's `pubspec.yaml` after
/// the `+` separator (for example `45` for `version: 1.2.3+45`), or the value
/// of the `--build-number` option if it was provided at build time.
///
/// This will be `null` if the version has no build number and no
/// `--build-number` option was provided.
const String? appBuildNumber = bool.hasEnvironment('FLUTTER_BUILD_NUMBER')
    ? String.fromEnvironment('FLUTTER_BUILD_NUMBER')
    : null;
