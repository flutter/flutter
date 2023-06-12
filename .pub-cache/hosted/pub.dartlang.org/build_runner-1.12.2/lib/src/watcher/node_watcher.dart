// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:watcher/watcher.dart';

import 'asset_change.dart';

Watcher _default(String path) => Watcher(path);

/// Allows watching significant files and directories in a given package.
class PackageNodeWatcher {
  final Watcher Function(String) _strategy;
  final PackageNode node;

  /// The actual watcher instance.
  Watcher _watcher;
  Watcher get watcher => _watcher;

  /// Creates a new watcher for a [PackageNode].
  ///
  /// May optionally specify a [watch] strategy, otherwise will attempt a
  /// reasonable default based on the current platform and the type of path
  /// (i.e. a file versus directory).
  PackageNodeWatcher(
    this.node, {
    Watcher Function(String path) watch,
  }) : _strategy = watch ?? _default;

  /// Returns a stream of records for assets that change recursively.
  Stream<AssetChange> watch() {
    assert(_watcher == null);
    _watcher = _strategy(node.path);
    final events = _watcher.events;
    return events.map((e) => AssetChange.fromEvent(node, e));
  }
}
