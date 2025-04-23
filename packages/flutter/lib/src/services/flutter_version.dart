// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @docImport 'dart:io'

/// Details about the Flutter version this app was compiled with,
/// corresponding to the output of `flutter --version`.
///
/// When this Flutter version was build from a fork, or when Flutter runs in a
/// custom embedder, these values might be unreliable.
///
/// See also:
///  - [Platform.version]
abstract final class FlutterVersion {
  const FlutterVersion._();

  /// The value is a [semantic versioning](https://semver.org/) string representing the
  /// version of the current Flutter version, possibly followed by whitespace and other
  /// version and build details.
  static const String? version =
      bool.hasEnvironment('FLUTTER_VERSION') ? String.fromEnvironment('FLUTTER_VERSION') : null;

  /// The Flutter channel used to compile the app.
  static const String? channel =
      bool.hasEnvironment('FLUTTER_CHANNEL') ? String.fromEnvironment('FLUTTER_CHANNEL') : null;

  /// The URL of the Git repository from which Flutter was obtained.
  static const String? gitUrl =
      bool.hasEnvironment('FLUTTER_GIT_URL') ? String.fromEnvironment('FLUTTER_GIT_URL') : null;

  /// The Flutter framework revision, as a (short) Git commit ID.
  static const String? frameworkRevision =
      bool.hasEnvironment('FLUTTER_FRAMEWORK_REVISION')
          ? String.fromEnvironment('FLUTTER_FRAMEWORK_REVISION')
          : null;

  /// The Flutter engine revision, as a (short) Git commit ID.
  static const String? engineRevision =
      bool.hasEnvironment('FLUTTER_ENGINE_REVISION')
          ? String.fromEnvironment('FLUTTER_ENGINE_REVISION')
          : null;

  /// The value is a [semantic versioning](https://semver.org/) string representing the
  /// version of the current Dart runtime, possibly followed by whitespace and other
  /// version and build details.
  ///
  /// On `dart:io` platforms it is more reliable to use [Platform.version].
  static const String? dartVersion =
      bool.hasEnvironment('FLUTTER_DART_VERSION')
          ? String.fromEnvironment('FLUTTER_DART_VERSION')
          : null;
}
