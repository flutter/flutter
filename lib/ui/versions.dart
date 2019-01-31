// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// Wraps version information for Dart, Skia and Flutter.
class Versions {

  /// Builds a versions object using the information
  /// we get from calling the native getVersions.
  factory Versions._internal() {
    final List<String> versions = _getVersions();
    return Versions._(versions[0], versions[1], versions[2]);
  }

  /// Private constructor to capture the versions.
  Versions._(
    this.dartVersion,
    this.skiaVersion,
    this.flutterEngineVersion
  ) : assert(dartVersion != null),
      assert(skiaVersion != null),
      assert(flutterEngineVersion != null);

  /// returns a vector with 3 versions.
  /// Dart, Skia and Flutter engine versions in this order.
  static List<String> _getVersions() native 'Versions_getVersions';

  final String dartVersion;
  final String skiaVersion;
  final String flutterEngineVersion;
}

/// [Versions] singleton. This object exposes Dart, Skia and
/// Flutter engine versions.
final Versions versions = Versions._internal();
