// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

enum VersionType {
  // Of the form x.y.z
  stable,
  // Of the form x.y.z-m.n.pre
  development,
  // Of the form x.y.z-m.n.pre.commits
  latest,
}

class Version {
  Version({
    @required this.x,
    @required this.y,
    @required this.z,
    this.m,
    this.n,
    this.commits,
    @required this.type,
  }) {
    switch (type) {
      case VersionType.stable:
        assert(m == null);
        assert(n == null);
        assert(commits == null);
        break;
      case VersionType.development:
        assert(m != null);
        assert(n != null);
        assert(commits == null);
        break;
      case VersionType.latest:
        assert(m != null);
        assert(n != null);
        assert(commits != null);
        break;
    }
  }

  factory Version.fromString(String versionString) {
    assert(versionString != null);

    final RegExp stablePattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');
    final RegExp developmentPattern =
        RegExp(r'^(\d+)\.(\d+)\.(\d+)-(\d+)\.(\d+)\.pre$');
    final RegExp latestPattern =
        RegExp(r'^(\d+)\.(\d+)\.(\d+)-(\d+)\.(\d+)\.pre\.(\d+)$');

    versionString = versionString.trim();
    // stable tag
    Match match = stablePattern.firstMatch(versionString);
    if (match != null) {
      // parse stable
      final List<int> parts =
          match.groups(<int>[1, 2, 3]).map(int.parse).toList();
      return Version(
        x: parts[0],
        y: parts[1],
        z: parts[2],
        type: VersionType.stable,
      );
    }
    // development tag
    match = developmentPattern.firstMatch(versionString);
    if (match != null) {
      // parse development
      final List<int> parts =
          match.groups(<int>[1, 2, 3, 4, 5]).map(int.parse).toList();
      return Version(
        x: parts[0],
        y: parts[1],
        z: parts[2],
        m: parts[3],
        n: parts[4],
        type: VersionType.development,
      );
    }
    // latest tag
    match = latestPattern.firstMatch(versionString);
    if (match != null) {
      // parse latest
      final List<int> parts =
          match.groups(<int>[1, 2, 3, 4, 5, 6]).map(int.parse).toList();
      return Version(
        x: parts[0],
        y: parts[1],
        z: parts[2],
        m: parts[3],
        n: parts[4],
        commits: parts[5],
        type: VersionType.latest,
      );
    }
    throw Exception('${versionString.trim()} cannot be parsed');
  }

  // Returns a new version with the given [increment] part incremented.
  // NOTE new version must be of same type as previousVersion.
  factory Version.increment(
    Version previousVersion,
    String increment, {
    VersionType nextVersionType,
  }) {
    final int nextX = previousVersion.x;
    int nextY = previousVersion.y;
    int nextZ = previousVersion.z;
    int nextM = previousVersion.m;
    int nextN = previousVersion.n;
    if (nextVersionType == null) {
      if (previousVersion.type == VersionType.latest) {
        nextVersionType = VersionType.development;
      } else {
        nextVersionType = previousVersion.type;
      }
    }

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
      type: nextVersionType,
    );
  }

  final int x;
  final int y;
  final int z;

  final int m;
  final int n;

  /// Number of commits past last tagged dev.
  final int commits;

  final VersionType type;

  @override
  String toString() {
    switch (type) {
      case VersionType.stable:
        return '$x.$y.$z';
      case VersionType.development:
        return '$x.$y.$z-$m.$n.pre';
      case VersionType.latest:
        return '$x.$y.$z-$m.$n.pre.$commits';
    }
    return null; // For analyzer
  }
}
