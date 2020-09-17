// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

enum VersionType {
  // Of the form x.y.z
  stable,
  // Of the form x.y.z-m.n.pre
  development,
}

class Version {
  Version({
    @required this.x,
    @required this.y,
    @required this.z,
    this.m,
    this.n,
    @required this.type,
  }) {
    switch (type) {
      case VersionType.stable:
        assert(m == null);
        assert(n == null);
        break;
      case VersionType.development:
        assert(m != null);
        assert(n != null);
        break;
    }
  }

  factory Version.fromString(String versionString) {
    assert(versionString != null);
    final Match match = versionPattern.firstMatch(versionString.trim());
    final List<int> parts = match.groups(<int>[1, 2, 3, 4, 5]).map(int.parse).toList();
    final VersionType type = parts[3] == null ? VersionType.stable : VersionType.development;
    return Version(
      x: parts[0],
      y: parts[1],
      z: parts[2],
      m: parts[3],
      n: parts[4],
      type: type,
    );
  }

  // Returns a new version with the given [increment] part incremented.
  // NOTE new version must be of same type as previousVersion.
  factory Version.increment(Version previousVersion, String increment) {
    final int nextX = previousVersion.x;
    int nextY = previousVersion.y;
    int nextZ = previousVersion.z;
    int nextM = previousVersion.m;
    int nextN = previousVersion.n;

    switch (increment) {
      case 'x':
        // This was probably a mistake.
        throw Exception('Incrementing x is not supported by this tool.');
        break;
      case 'y':
        // Dev release following a beta release.
        nextY += 1;
        nextZ = 0;
        if (previousVersion.type != VersionType.stable) {
          nextM = 0;
          nextN = 0;
        }
        break;
      case 'z':
        // Hotfix to stable release.
        assert(previousVersion.type == VersionType.stable);
        nextZ += 1;
        break;
      case 'm':
        // Regular dev release.
        assert(previousVersion.type == VersionType.development);
        assert(nextM != null);
        nextM += 1;
        nextN = 0;
        break;
      case 'n':
        // Hotfix to internal roll.
        nextN += 1;
        break;
      default:
        throw Exception('Unknown increment level $increment.');
    }
    return Version(
      x: nextX,
      y: nextY,
      z: nextZ,
      m: nextM,
      n: nextN,
      type: previousVersion.type,
    );
  }

  final int x;
  final int y;
  final int z;

  final int m;
  final int n;

  final VersionType type;

  static RegExp versionPattern = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)-(\d+)\.(\d+)\.pre$',
  );

  @override
  String toString() {
    if (type == VersionType.stable) {
      return '$x.$y.$z';
    } else {
      return '$x.$y.$z-$m.$n.pre';
    }
  }
}
