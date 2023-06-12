// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset/finalized_reader.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:_test_common/common.dart';

void main() {
  group('FinalizedReader', () {
    FinalizedReader reader;
    AssetGraph graph;

    setUp(() async {
      graph = await AssetGraph.build([], <AssetId>{}, <AssetId>{},
          buildPackageGraph({rootPackage('foo'): []}), null);
    });

    test('can not read deleted files', () async {
      var notDeleted = makeAssetNode(
          'a|web/a.txt', [], computeDigest(AssetId('a', 'web/a.txt'), 'a'));
      var deleted = makeAssetNode(
          'a|lib/b.txt', [], computeDigest(AssetId('a', 'lib/b.txt'), 'b'));
      deleted.deletedBy.add(deleted.id.addExtension('.post_anchor.1'));

      graph..add(notDeleted)..add(deleted);

      var delegate = InMemoryAssetReader();
      delegate.assets.addAll({notDeleted.id: [], deleted.id: []});

      reader = FinalizedReader(delegate, graph, [], 'a');
      expect(await reader.canRead(notDeleted.id), true);
      expect(await reader.canRead(deleted.id), false);
    });

    test('Failure nodes interact well with build filters ', () async {
      var id = AssetId('a', 'web/a.txt');
      var node = GeneratedAssetNode(id,
          state: NodeState.upToDate,
          phaseNumber: 0,
          wasOutput: true,
          isFailure: true,
          primaryInput: AssetId('a', 'web/a.dart'),
          isHidden: true,
          builderOptionsId: AssetId('a', 'builder_options'));
      graph.add(node);
      var delegate = InMemoryAssetReader();
      delegate.assets.addAll({id: []});
      reader = FinalizedReader(delegate, graph,
          [InBuildPhase(TestBuilder(), 'a', isOptional: false)], 'a')
        ..reset({'web'}, {});
      expect(await reader.unreadableReason(id), UnreadableReason.failed,
          reason: 'Should report a failure if no build filters apply');

      reader.reset({'web'}, {BuildFilter(Glob('b'), Glob('foo'))});
      expect(await reader.unreadableReason(id), UnreadableReason.notOutput,
          reason:
              'Should report as not output if it doesn\'t match requested build filters');
    });
  });
}
