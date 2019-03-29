// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

/// Wraps version information for Dart, Skia and Flutter.
class Versions {
  /// Private constructor to capture the versions.
  Versions._(
    this.dartVersion,
    this.skiaVersion,
    this.flutterEngineVersion
  ) : assert(dartVersion != null),
      assert(skiaVersion != null),
      assert(flutterEngineVersion != null);

  final String dartVersion;
  final String skiaVersion;
  final String flutterEngineVersion;
}

/// [Versions] singleton. This object exposes Dart, Skia and
/// Flutter engine versions.
final Versions versions = Versions._('', '', '');
