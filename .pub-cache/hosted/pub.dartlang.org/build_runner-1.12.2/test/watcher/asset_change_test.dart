// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner_core/src/package_graph/package_graph.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('AssetChange', () {
    test('should be equal if asset and type are equivalent', () {
      AssetId asset(String name) => AssetId(name, 'lib/$asset.dart');
      final pkgA1 = asset('a');
      final pkgA2 = asset('a');

      final change1 = AssetChange(pkgA1, ChangeType.ADD);
      final change2 = AssetChange(pkgA2, ChangeType.ADD);

      expect(change1, equals(change2));

      final change3 = AssetChange(pkgA1, ChangeType.MODIFY);
      expect(change1, isNot(equals(change3)));

      final pkgB = asset('b');
      final change4 = AssetChange(pkgB, ChangeType.ADD);
      expect(change1, isNot(equals(change4)));
    });

    test('should support relative paths', () {
      final pkgBar = p.join('/', 'foo', 'bar');
      final barFile =
          p.join(p.relative(pkgBar, from: p.current), 'lib', 'bar.dart');
      final nodeBar = PackageNode('bar', pkgBar, null, null);

      final event = WatchEvent(ChangeType.ADD, barFile);
      final change = AssetChange.fromEvent(nodeBar, event);

      expect(change.id.package, 'bar');
      expect(change.id.path, p.join('lib', 'bar.dart'));
    });

    test('should normalize absolute paths to relative', () {
      final pkgBar = p.join('/', 'foo', 'bar');
      final barFile = p.join('/', 'foo', 'bar', 'lib', 'bar.dart');

      final nodeBar = PackageNode('bar', pkgBar, null, null);
      final event = WatchEvent(ChangeType.ADD, barFile);
      final change = AssetChange.fromEvent(nodeBar, event);

      expect(change.id.package, 'bar');
      expect(change.id.path, p.join('lib', 'bar.dart'));
    });
  });
}
