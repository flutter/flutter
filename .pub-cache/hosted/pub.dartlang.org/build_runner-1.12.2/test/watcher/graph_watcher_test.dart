// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_test_common/package_graphs.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:build_runner_core/src/package_graph/package_graph.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('PackageGraphWatcher', () {
    test('should aggregate changes from all nodes', () {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/b', type: DependencyType.path): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        'b': FakeNodeWatcher(graph['b']),
        r'$sdk': FakeNodeWatcher(null),
      };
      final watcher = PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });

      nodes['a'].emitAdd('lib/a.dart');
      nodes['b'].emitAdd('lib/b.dart');

      expect(
          watcher.watch(),
          emitsInOrder([
            AssetChange(AssetId('a', 'lib/a.dart'), ChangeType.ADD),
            AssetChange(AssetId('b', 'lib/b.dart'), ChangeType.ADD),
          ]));
    });

    test('should avoid duplicate changes with nested packages', () async {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/a/b', type: DependencyType.path): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a'])..markReady(),
        'b': FakeNodeWatcher(graph['b'])..markReady(),
      };
      final watcher = PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });

      final events = <AssetChange>[];
      unawaited(watcher.watch().forEach(events.add));
      await watcher.ready;

      nodes['a'].emitAdd('b/lib/b.dart');
      nodes['b'].emitAdd('lib/b.dart');

      await pumpEventQueue();

      expect(events, [AssetChange(AssetId('b', 'lib/b.dart'), ChangeType.ADD)]);
    });

    test('should avoid watchers on pub dependencies', () {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/a/b/', type: DependencyType.hosted): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        r'$sdk': FakeNodeWatcher(null),
      };
      PackageNodeWatcher noBWatcher(PackageNode node) {
        if (node.name == 'b') throw StateError('No watcher for B!');
        return nodes[node.name];
      }

      final watcher = PackageGraphWatcher(graph, watch: noBWatcher);

      unawaited(watcher.watch().drain());

      for (final node in nodes.values) {
        node.markReady();
      }

      expect(watcher.ready, completes);
    });

    test('ready waits for all node watchers to be ready', () async {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/b', type: DependencyType.path): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        'b': FakeNodeWatcher(graph['b']),
        r'$sdk': FakeNodeWatcher(null),
      };
      final watcher = PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });
      // We have to listen in order for `ready` to complete.
      unawaited(watcher.watch().drain());

      var done = false;
      unawaited(watcher.ready.then((_) => done = true));
      await Future<void>.value();

      for (final node in nodes.values) {
        expect(done, isFalse);
        node.markReady();
        await Future<void>.value();
      }

      await Future<void>.value();
      expect(done, isTrue);
    });
  });
}

class FakeNodeWatcher implements PackageNodeWatcher {
  @override
  final PackageNode node;
  final _events = StreamController<AssetChange>();

  FakeNodeWatcher(this.node);

  @override
  Watcher get watcher => _watcher;
  final _watcher = _FakeWatcher();

  void markReady() => _watcher._readyCompleter.complete();

  void emitAdd(String path) {
    _events.add(
      AssetChange(
        AssetId(node.name, path),
        ChangeType.ADD,
      ),
    );
  }

  @override
  Stream<AssetChange> watch() => _events.stream;
}

class _FakeWatcher implements Watcher {
  @override
  Stream<WatchEvent> get events => throw UnimplementedError();

  @override
  bool get isReady => _readyCompleter.isCompleted;

  @override
  String get path => throw UnimplementedError();

  @override
  Future get ready => _readyCompleter.future;
  final _readyCompleter = Completer();
}
