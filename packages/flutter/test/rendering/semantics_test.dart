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

    test('actions', () {
      final SemanticsNode node = new SemanticsNode();
      const SemanticsAction actionTap = SemanticsAction.tap;
      const SemanticsAction actionLongPress = SemanticsAction.longPress;

      expect(node, isNot(hasAction(actionTap)));
      expect(node, isNot(hasAction(actionLongPress)));

      node.ensureAction(actionTap);
      expect(node, hasAction(actionTap));
      expect(node, isNot(hasAction(actionLongPress)));

      node.ensureAction(actionLongPress, isPresent: false);
      expect(node, hasAction(actionTap));
      expect(node, isNot(hasAction(actionLongPress)));

      node.ensureAction(actionLongPress, isPresent: true);
      expect(node, hasAction(actionTap));
      expect(node, hasAction(actionLongPress));

      node.ensureAction(actionLongPress, isPresent: true);
      expect(node, hasAction(actionTap));
      expect(node, hasAction(actionLongPress));

      node.ensureAction(actionTap, isPresent: false);
      expect(node, isNot(hasAction(actionTap)));
      expect(node, hasAction(actionLongPress));

      node.ensureAction(actionLongPress, isPresent: false);
      expect(node, isNot(hasAction(actionTap)));
      expect(node, isNot(hasAction(actionLongPress)));
    });

    test('scrolling and adjustment actions', () {
      final SemanticsNode node = new SemanticsNode();

      node.ensureHorizontalScrollingActions();
      expect(node, hasAction(SemanticsAction.scrollUp));
      expect(node, hasAction(SemanticsAction.scrollDown));

      node.ensureHorizontalScrollingActions(arePresent: false);
      expect(node, isNot(hasAction(SemanticsAction.scrollUp)));
      expect(node, isNot(hasAction(SemanticsAction.scrollDown)));

      node.ensureVerticalScrollingActions();
      expect(node, hasAction(SemanticsAction.scrollLeft));
      expect(node, hasAction(SemanticsAction.scrollRight));

      node.ensureVerticalScrollingActions(arePresent: false);
      expect(node, isNot(hasAction(SemanticsAction.scrollLeft)));
      expect(node, isNot(hasAction(SemanticsAction.scrollRight)));
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
