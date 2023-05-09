// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$IntervalTree', () {
    test('is balanced', () {
      final Map<String, List<CodePointRange>> ranges = <String, List<CodePointRange>>{
        'A': const <CodePointRange>[CodePointRange(0, 5), CodePointRange(6, 10)],
        'B': const <CodePointRange>[CodePointRange(4, 6)],
      };

      // Should create a balanced 3-node tree with a root with a left and right
      // child.
      final IntervalTree<String> tree = IntervalTree<String>.createFromRanges(ranges);
      final IntervalTreeNode<String> root = tree.root;
      expect(root.left, isNotNull);
      expect(root.right, isNotNull);
      expect(root.left!.left, isNull);
      expect(root.left!.right, isNull);
      expect(root.right!.left, isNull);
      expect(root.right!.right, isNull);

      // Should create a balanced 15-node tree (4 layers deep).
      final Map<String, List<CodePointRange>> ranges2 = <String, List<CodePointRange>>{
        'A': const <CodePointRange>[
          CodePointRange(1, 1),
          CodePointRange(2, 2),
          CodePointRange(3, 3),
          CodePointRange(4, 4),
          CodePointRange(5, 5),
          CodePointRange(6, 6),
          CodePointRange(7, 7),
          CodePointRange(8, 8),
          CodePointRange(9, 9),
          CodePointRange(10, 10),
          CodePointRange(11, 11),
          CodePointRange(12, 12),
          CodePointRange(13, 13),
          CodePointRange(14, 14),
          CodePointRange(15, 15),
        ],
      };

      // Should create a balanced 3-node tree with a root with a left and right
      // child.
      final IntervalTree<String> tree2 = IntervalTree<String>.createFromRanges(ranges2);
      final IntervalTreeNode<String> root2 = tree2.root;

      expect(root2.left!.left!.left, isNotNull);
      expect(root2.left!.left!.right, isNotNull);
      expect(root2.left!.right!.left, isNotNull);
      expect(root2.left!.right!.right, isNotNull);
      expect(root2.right!.left!.left, isNotNull);
      expect(root2.right!.left!.right, isNotNull);
      expect(root2.right!.right!.left, isNotNull);
      expect(root2.right!.right!.right, isNotNull);
    });

    test('finds values whose intervals overlap with a given point', () {
      final Map<String, List<CodePointRange>> ranges = <String, List<CodePointRange>>{
        'A': const <CodePointRange>[CodePointRange(0, 5), CodePointRange(7, 10)],
        'B': const <CodePointRange>[CodePointRange(4, 6)],
      };
      final IntervalTree<String> tree = IntervalTree<String>.createFromRanges(ranges);

      expect(tree.intersections(1), <String>['A']);
      expect(tree.intersections(4), <String>['A', 'B']);
      expect(tree.intersections(6), <String>['B']);
      expect(tree.intersections(7), <String>['A']);
      expect(tree.intersections(11), <String>[]);
    });
  });
}
