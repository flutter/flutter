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

      node.addTag(tag1);
      expect(node.hasTag(tag1), isTrue);
      expect(node.hasTag(tag2), isFalse);

      node.addTag(tag2);
      expect(node.hasTag(tag1), isTrue);
      expect(node.hasTag(tag2), isTrue);
    });

    test('getSemanticsData includes tags', () {
      final SemanticsNode node = new SemanticsNode()
        ..addTag(tag1)
        ..addTag(tag2);

      final Set<SemanticsTag> expected = new Set<SemanticsTag>()
        ..add(tag1)
        ..add(tag2);

      expect(node.getSemanticsData().tags, expected);

      node.mergeAllDescendantsIntoThisNode = true;
      node.addChildren(<SemanticsNode>[
        new SemanticsNode()..addTag(tag3)
      ]);
      node.finalizeChildren();

      expected.add(tag3);

      expect(node.getSemanticsData().tags, expected);
    });
  });
}

Matcher hasAction(SemanticsAction action) => new _HasAction(action);

class _HasAction extends Matcher {
  const _HasAction(this.action,) : assert(action != null);

  final SemanticsAction action;

  @override
  bool matches(covariant SemanticsNode node, Map<dynamic, dynamic> matchState) {
    return node.getSemanticsData().hasAction(action);
  }

  @override
  Description describe(Description description) {
    return description.add('has $action');
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    return mismatchDescription.add('node does not have $action');
  }
}
