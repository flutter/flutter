// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';


void main() {
  group('SemanticsNode', () {

    const SemanticsTag tag1 = const SemanticsTag('Tag One');
    const SemanticsTag tag2 = const SemanticsTag('Tag Two');
    const SemanticsTag tag3 = const SemanticsTag('Tag Three');

    test('tagging', () {
      final SemanticsNode node = new SemanticsNode();

      expect(node.hasTag(tag1), isFalse);
      expect(node.hasTag(tag2), isFalse);

      node.ensureTag(tag1);
      expect(node.hasTag(tag1), isTrue);
      expect(node.hasTag(tag2), isFalse);

      node.ensureTag(tag2, isPresent: false);
      expect(node.hasTag(tag1), isTrue);
      expect(node.hasTag(tag2), isFalse);

      node.ensureTag(tag2, isPresent: true);
      expect(node.hasTag(tag1), isTrue);
      expect(node.hasTag(tag2), isTrue);

      node.ensureTag(tag2, isPresent: true);
      expect(node.hasTag(tag1), isTrue);
      expect(node.hasTag(tag2), isTrue);

      node.ensureTag(tag1, isPresent: false);
      expect(node.hasTag(tag1), isFalse);
      expect(node.hasTag(tag2), isTrue);

      node.ensureTag(tag2, isPresent: false);
      expect(node.hasTag(tag1), isFalse);
      expect(node.hasTag(tag2), isFalse);
    });

    test('getSemanticsData includes tags', () {
      final SemanticsNode node = new SemanticsNode()
        ..ensureTag(tag1)
        ..ensureTag(tag2);

      final Set<SemanticsTag> expected = new Set<SemanticsTag>()
        ..add(tag1)
        ..add(tag2);

      expect(node.getSemanticsData().tags, expected);

      node.mergeAllDescendantsIntoThisNode = true;
      node.addChildren(<SemanticsNode>[
        new SemanticsNode()..ensureTag(tag3)
      ]);
      node.finalizeChildren();

      expected.add(tag3);

      expect(node.getSemanticsData().tags, expected);
    });
  });

}
