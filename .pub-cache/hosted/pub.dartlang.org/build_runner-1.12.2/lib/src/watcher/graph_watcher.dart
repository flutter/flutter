// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:logging/logging.dart';

import 'asset_change.dart';
import 'node_watcher.dart';

PackageNodeWatcher _default(PackageNode node) => PackageNodeWatcher(node);

/// Allows watching an entire graph of packages to schedule rebuilds.
class PackageGraphWatcher {
  // TODO: Consider pulling logging out and providing hooks instead.
  final Logger _logger;
  final PackageNodeWatcher Function(PackageNode) _strategy;
  final PackageGraph _graph;

  final _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  bool _isWatching = false;

  /// Creates a new watcher for a [PackageGraph].
  ///
  /// May optionally specify a [watch] strategy, otherwise will attempt a
  /// reasonable default based on the current platform.
  PackageGraphWatcher(
    this._graph, {
    Logger logger,
    PackageNodeWatcher Function(PackageNode node) watch,
  })  : _logger = logger ?? Logger('build_runner'),
        _strategy = watch ?? _default;

  /// Returns a stream of records for assets that changed in the package graph.
  Stream<AssetChange> watch() {
    assert(!_isWatching);
    _isWatching = true;
    return LazyStream(
        () => logTimedSync(_logger, 'Setting up file watchers', _watch));
  }

  Stream<AssetChange> _watch() {
    final allWatchers = _graph.allPackages.values
        .where((node) => node.dependencyType == DependencyType.path)
        .map(_strategy)
        .toList();
    final filteredEvents = allWatchers
        .map((w) => w
                .watch()
                .where(_nestedPathFilter(w.node))
                .handleError((dynamic e, StackTrace s) {
              _logger.severe(
                  'Error from directory watcher for package:${w.node.name}\n\n'
                  'If you see this consistently then it is recommended that '
                  'you enable the polling file watcher with '
                  '--use-polling-watcher.');
              throw e;
            }))
        .toList();
    // Asynchronously complete the `_readyCompleter` once all the watchers
    // are done.
    () async {
      await Future.wait(
          allWatchers.map((nodeWatcher) => nodeWatcher.watcher.ready));
      _readyCompleter.complete();
    }();
    return StreamGroup.merge(filteredEvents);
  }

  bool Function(AssetChange) _nestedPathFilter(PackageNode rootNode) {
    final ignorePaths = _nestedPaths(rootNode);
    return (change) => !ignorePaths.any(change.id.path.startsWith);
  }

  // Returns a set of all package paths that are "nested" within a node.
  //
  // This allows the watcher to optimize and avoid duplicate events.
  List<String> _nestedPaths(PackageNode rootNode) {
    return _graph.allPackages.values
        .where((node) {
          return node.path.length > rootNode.path.length &&
              node.path.startsWith(rootNode.path);
        })
        .map((node) =>
            node.path.substring(rootNode.path.length + 1) +
            Platform.pathSeparator)
        .toList();
  }
}
