// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// [FlutterVersion] contains various meta information about whith which Flutter build this app was compiled.
/// This contains the information that is output by executing `flutter --version`.
/// 
/// See also:
///  - [Platform.version](https://api.dart.dev/stable/dart-io/Platform/version.html)
class FlutterVersion {
  FlutterVersion._();

  /// The Flutter version used to compile the app.
  static const String version = String.fromEnvironment('FLUTTER_VERSION');

  /// The Flutter channel used to compile the app.
  static const String channel = String.fromEnvironment('FLUTTER_CHANNEL');

  /// The link to the Git URL from which Flutter is obtained.
  static const String gitUrl = String.fromEnvironment('FLUTTER_GIT_URL');

  /// The Flutter framework revision.
  static const String frameworkRevision = String.fromEnvironment('FLUTTER_FRAMEWORK_REVISION');

  /// The Flutter engine revision.
  static const String engineRevision = String.fromEnvironment('FLUTTER_ENGINE_REVISION');

  // This is included, since [Platform.version](https://api.dart.dev/stable/dart-io/Platform/version.html)
  // is not included on web platforms.
  /// The Dart version used to compile the app.
  static const String dartVersion = String.fromEnvironment('FLUTTER_DART_VERSION');
}
