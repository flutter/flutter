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
      final Map<String, List<CodeunitRange>> ranges = <String, List<CodeunitRange>>{
        'A': const <CodeunitRange>[CodeunitRange(0, 5), CodeunitRange(6, 10)],
        'B': const <CodeunitRange>[CodeunitRange(4, 6)],
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
      final Map<String, List<CodeunitRange>> ranges2 = <String, List<CodeunitRange>>{
        'A': const <CodeunitRange>[
          CodeunitRange(1, 1),
          CodeunitRange(2, 2),
          CodeunitRange(3, 3),
          CodeunitRange(4, 4),
          CodeunitRange(5, 5),
          CodeunitRange(6, 6),
          CodeunitRange(7, 7),
          CodeunitRange(8, 8),
          CodeunitRange(9, 9),
          CodeunitRange(10, 10),
          CodeunitRange(11, 11),
          CodeunitRange(12, 12),
          CodeunitRange(13, 13),
          CodeunitRange(14, 14),
          CodeunitRange(15, 15),
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
      final Map<String, List<CodeunitRange>> ranges = <String, List<CodeunitRange>>{
        'A': const <CodeunitRange>[CodeunitRange(0, 5), CodeunitRange(7, 10)],
        'B': const <CodeunitRange>[CodeunitRange(4, 6)],
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
