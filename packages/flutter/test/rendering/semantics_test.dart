// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';


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

    test('after markNeedsSemanticsUpdate(onlyLocalUpdates: true) all render objects between two semantic boundaries are asked for annotations', () {
      renderer.pipelineOwner.ensureSemantics();

      TestRender middle;
      final TestRender root = new TestRender(
        action: SemanticsAction.tap,
        isSemanticBoundary: true,
        child: new TestRender(
          action: SemanticsAction.longPress,
          isSemanticBoundary: false,
          child: middle = new TestRender(
            action: SemanticsAction.scrollLeft,
            isSemanticBoundary: false,
            child: new TestRender(
              action: SemanticsAction.scrollRight,
              isSemanticBoundary: false,
              child: new TestRender(
                action: SemanticsAction.scrollUp,
                isSemanticBoundary: true,
              )
            )
          )
        )
      );

      layout(root);
      pumpFrame(phase: EnginePhase.flushSemantics);

      int expectedActions = SemanticsAction.tap.index | SemanticsAction.longPress.index | SemanticsAction.scrollLeft.index | SemanticsAction.scrollRight.index;
      expect(root.debugSemantics.getSemanticsData().actions, expectedActions);

      middle.action = SemanticsAction.scrollDown;
      middle.markNeedsSemanticsUpdate(onlyLocalUpdates: true);
      expect(root.debugSemantics.getSemanticsData().actions, 0); // SemanticsNode is reset

      pumpFrame(phase: EnginePhase.flushSemantics);

      expectedActions = SemanticsAction.tap.index | SemanticsAction.longPress.index | SemanticsAction.scrollDown.index | SemanticsAction.scrollRight.index;
      expect(root.debugSemantics.getSemanticsData().actions, expectedActions);
    });
  });
}

class TestRender extends RenderProxyBox {

  TestRender({ this.action, this.isSemanticBoundary, RenderObject child }) : super(child);

  @override
  final bool isSemanticBoundary;

  SemanticsAction action;

  @override
  SemanticsAnnotator get semanticsAnnotator => _annotate;

  void _annotate(SemanticsNode node) {
    node.addAction(action);
  }

}
