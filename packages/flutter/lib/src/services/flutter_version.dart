// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// [FlutterVersion] contains various meta information about with which
/// Flutter version this app was compiled.
/// It tries to mimic the information that is seen when executing `flutter --version`.
///
/// When this Flutter version was build from a fork, or when Flutter runs in a
/// custom embedder, these values might be unreliable.
///
/// See also:
///  - [Platform.version](https://api.dart.dev/stable/dart-io/Platform/version.html)
abstract final class FlutterVersion {
  const FlutterVersion._();

  /// The Flutter version used to compile the app.
  static const String? version =
      String.fromEnvironment('FLUTTER_VERSION') != ''
          ? String.fromEnvironment('FLUTTER_VERSION')
          : null;

  /// The Flutter channel used to compile the app.
  static const String? channel =
      String.fromEnvironment('FLUTTER_CHANNEL') != ''
          ? String.fromEnvironment('FLUTTER_CHANNEL')
          : null;

  /// The link to the Git URL from which Flutter is obtained.
  static const String? gitUrl =
      String.fromEnvironment('FLUTTER_GIT_URL') != ''
          ? String.fromEnvironment('FLUTTER_GIT_URL')
          : null;

  /// The Flutter framework revision.
  static const String? frameworkRevision =
      String.fromEnvironment('FLUTTER_FRAMEWORK_REVISION') != ''
          ? String.fromEnvironment('FLUTTER_FRAMEWORK_REVISION')
          : null;

  /// The Flutter engine revision.
  static const String? engineRevision =
      String.fromEnvironment('FLUTTER_ENGINE_REVISION') != ''
          ? String.fromEnvironment('FLUTTER_ENGINE_REVISION')
          : null;

  // This is included since [Platform.version](https://api.dart.dev/stable/dart-io/Platform/version.html)
  // is not included on web platforms.
  /// The Dart version used to compile the app.
  static const String? dartVersion =
      String.fromEnvironment('FLUTTER_DART_VERSION') != ''
          ? String.fromEnvironment('FLUTTER_DART_VERSION')
          : null;
}
