// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset/reader.dart';
import '../asset_graph/graph.dart';
import '../package_graph/package_graph.dart';

/// Functionality for detecting if the build script itself or any of its
/// transitive imports have changed.
abstract class BuildScriptUpdates {
  /// Checks if the current running program has been updated, based on
  /// [updatedIds].
  bool hasBeenUpdated(Set<AssetId> updatedIds);

  /// Creates a [BuildScriptUpdates] object, using [reader] to ensure that
  /// the [assetGraph] is tracking digests for all transitive sources.
  ///
  /// If [disabled] is `true` then all checks are skipped and
  /// [hasBeenUpdated] will always return `false`.
  static Future<BuildScriptUpdates> create(RunnerAssetReader reader,
      PackageGraph packageGraph, AssetGraph assetGraph,
      {bool disabled = false}) async {
    disabled ??= false;
    if (disabled) return _NoopBuildScriptUpdates();
    return _MirrorBuildScriptUpdates.create(reader, packageGraph, assetGraph);
  }
}

/// Uses mirrors to find all transitive imports of the current script.
class _MirrorBuildScriptUpdates implements BuildScriptUpdates {
  final Set<AssetId> _allSources;
  final bool _supportsIncrementalRebuilds;

  _MirrorBuildScriptUpdates._(
      this._supportsIncrementalRebuilds, this._allSources);

  static Future<BuildScriptUpdates> create(RunnerAssetReader reader,
      PackageGraph packageGraph, AssetGraph graph) async {
    var supportsIncrementalRebuilds = true;
    var rootPackage = packageGraph.root.name;
    Set<AssetId> allSources;
    var logger = Logger('BuildScriptUpdates');
    try {
      allSources = _urisForThisScript
          .map((id) => _idForUri(id, rootPackage))
          .where((id) => id != null)
          .toSet();
      var missing = allSources.firstWhere((id) => !graph.contains(id),
          orElse: () => null);
      if (missing != null) {
        supportsIncrementalRebuilds = false;
        logger.warning('$missing was not found in the asset graph, '
            'incremental builds will not work.\n This probably means you '
            'don\'t have your dependencies specified fully in your '
            'pubspec.yaml.');
      } else {
        // Make sure we are tracking changes for all ids in [allSources].
        for (var id in allSources) {
          graph.get(id).lastKnownDigest ??= await reader.digest(id);
        }
      }
    } on ArgumentError catch (_) {
      supportsIncrementalRebuilds = false;
      allSources = <AssetId>{};
    }
    return _MirrorBuildScriptUpdates._(supportsIncrementalRebuilds, allSources);
  }

  static Iterable<Uri> get _urisForThisScript =>
      currentMirrorSystem().libraries.keys;

  /// Checks if the current running program has been updated, based on
  /// [updatedIds].
  @override
  bool hasBeenUpdated(Set<AssetId> updatedIds) {
    if (!_supportsIncrementalRebuilds) return true;
    return updatedIds.intersection(_allSources).isNotEmpty;
  }

  /// Attempts to return an [AssetId] for [uri].
  ///
  /// Returns `null` if the uri should be ignored, or throws an [ArgumentError]
  /// if the [uri] is not recognized.
  static AssetId _idForUri(Uri uri, String _rootPackage) {
    switch (uri.scheme) {
      case 'dart':
        // TODO: check for sdk updates!
        break;
      case 'package':
        var parts = uri.pathSegments;
        return AssetId(parts[0],
            p.url.joinAll(['lib', ...parts.getRange(1, parts.length)]));
      case 'file':
        var relativePath = p.relative(uri.toFilePath(), from: p.current);
        return AssetId(_rootPackage, relativePath);
      case 'data':
        // Test runner uses a `data` scheme, don't invalidate for those.
        if (uri.path.contains('package:test')) break;
        continue unsupported;
      case 'http':
        continue unsupported;
      unsupported:
      default:
        throw ArgumentError('Unsupported uri scheme `${uri.scheme}` found for '
            'library in build script.\n'
            'This probably means you are running in an unsupported '
            'context, such as in an isolate or via `pub run`.\n'
            'Full uri was: $uri.');
    }
    return null;
  }
}

/// Always returns false for [hasBeenUpdated], used when we want to skip
/// the build script checks.
class _NoopBuildScriptUpdates implements BuildScriptUpdates {
  @override
  bool hasBeenUpdated(void _) => false;
}
