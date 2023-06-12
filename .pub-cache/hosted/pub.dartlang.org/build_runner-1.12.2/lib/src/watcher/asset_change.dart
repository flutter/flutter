// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'package:build_runner_core/build_runner_core.dart';

/// Represents an [id] that was modified on disk as a result of [type].
class AssetChange {
  /// Asset that was changed.
  final AssetId id;

  /// What caused the asset to be detected as changed.
  final ChangeType type;

  const AssetChange(this.id, this.type);

  /// Creates a new change record in [package] from an existing watcher [event].
  AssetChange.fromEvent(PackageNode package, WatchEvent event)
      : this(AssetId(package.name, _normalizeRelativePath(package, event)),
            event.type);

  static String _normalizeRelativePath(PackageNode package, WatchEvent event) {
    final pkgPath = package.path;
    var absoluteEventPath =
        p.isAbsolute(event.path) ? event.path : p.absolute(event.path);
    if (!p.isWithin(pkgPath, absoluteEventPath)) {
      throw ArgumentError('"$absoluteEventPath" is not in "$pkgPath".');
    }
    return p.relative(absoluteEventPath, from: pkgPath);
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AssetChange && other.id == id && other.type == type;

  @override
  String toString() => 'AssetChange {asset: $id, type: $type}';
}
