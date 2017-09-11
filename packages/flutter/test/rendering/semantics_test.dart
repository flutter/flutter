// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

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

  test('toStringDeep() does not throw with transform == null', () {
    final SemanticsNode child1 = new SemanticsNode();
    final SemanticsNode child2 = new SemanticsNode();
    final SemanticsNode root = new SemanticsNode();
    root.addChildren(<SemanticsNode>[child1, child2]);
    root.finalizeChildren();

    expect(root.transform, isNull);
    expect(child1.transform, isNull);
    expect(child2.transform, isNull);

    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversal),
      'SemanticsNode#8(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '├SemanticsNode#6(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '└SemanticsNode#7(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n',
    );
  });

  test('toStringDeep respects childOrder parameter', () {
    final SemanticsNode child1 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(20.0, 20.0, 20.0, 20.0);
    final SemanticsNode child2 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(10.0, 10.0, 10.0, 10.0);
    final SemanticsNode root = new SemanticsNode();
    root.addChildren(<SemanticsNode>[child1, child2]);
    root.finalizeChildren();
    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversal),
      'SemanticsNode#11(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '├SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 10.0, 10.0, 10.0))\n'
      '└SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(20.0, 20.0, 20.0, 20.0))\n',
    );

    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest),
      'SemanticsNode#11(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '├SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(20.0, 20.0, 20.0, 20.0))\n'
      '└SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 10.0, 10.0, 10.0))\n',
    );

    final SemanticsNode child3 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(0.0, 0.0, 0.0, 0.0);
    child3.addChildren(<SemanticsNode>[
      new SemanticsNode()..rect = new Rect.fromLTRB(20.0, 0.0, 20.0, 0.0),
      new SemanticsNode(),
    ]);
    child3.finalizeChildren();

    final SemanticsNode rootComplex = new SemanticsNode();
    rootComplex.addChildren(<SemanticsNode>[child1, child2, child3]);
    rootComplex.finalizeChildren();

    expect(
      rootComplex.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversal),
      'SemanticsNode#15(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '├SemanticsNode#12(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '│├SemanticsNode#14(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '│└SemanticsNode#13(STALE, owner: null, Rect.fromLTRB(20.0, 0.0, 20.0, 0.0))\n'
      '├SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 10.0, 10.0, 10.0))\n'
      '└SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(20.0, 20.0, 20.0, 20.0))\n',
    );

    expect(
      rootComplex.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest),
      'SemanticsNode#15(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      '├SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(20.0, 20.0, 20.0, 20.0))\n'
      '├SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 10.0, 10.0, 10.0))\n'
      '└SemanticsNode#12(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n'
      ' ├SemanticsNode#13(STALE, owner: null, Rect.fromLTRB(20.0, 0.0, 20.0, 0.0))\n'
      ' └SemanticsNode#14(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n',
    );
  });

  test('debug properties', () {
    expect(
      new SemanticsNode().toStringDeep(),
      'SemanticsNode#16(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n',
    );

    final SemanticsNode allProperties = new SemanticsNode()
      ..rect = new Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..mergeAllDescendantsIntoThisNode = true
      ..transform = new Matrix4.translation(new Vector3(10.0, 10.0, 0.0))
      ..wasAffectedByClip = true
      ..addAction(SemanticsAction.scrollUp)
      ..addAction(SemanticsAction.longPress)
      ..addAction(SemanticsAction.showOnScreen)
      ..isChecked = false
      ..isSelected = true
      ..label = "Use all the properties"
      ..textDirection = TextDirection.rtl;
    expect(
      allProperties.toStringDeep(),
      'SemanticsNode#17(STALE, owner: null, leaf merge, Rect.fromLTRB(60.0, 20.0, 80.0, 50.0), clipped, actions: [longPress, scrollUp, showOnScreen], selected, label: "Use all the properties", textDirection: rtl)\n',
    );
    expect(
      allProperties.getSemanticsData().toString(),
      'SemanticsData(Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), [1.0,0.0,0.0,10.0; 0.0,1.0,0.0,10.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0], actions: [longPress, scrollUp, showOnScreen], flags: [isSelected], label: "Use all the properties", textDirection: rtl)',
    );

    final SemanticsNode scaled = new SemanticsNode()
      ..rect = new Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = new Matrix4.diagonal3(new Vector3(10.0, 10.0, 1.0));
    expect(
      scaled.toStringDeep(),
      'SemanticsNode#18(STALE, owner: null, Rect.fromLTRB(50.0, 10.0, 70.0, 40.0) scaled by 10.0x)\n',
    );
    expect(
      scaled.getSemanticsData().toString(),
      'SemanticsData(Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), [10.0,0.0,0.0,0.0; 0.0,10.0,0.0,0.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0])',
    );
  });

  test('reset clears tags', () {
    const SemanticsTag tag = const SemanticsTag('tag for testing');
    final SemanticsNode node = new SemanticsNode();

    expect(node.hasTag(tag), isFalse);

    node.addTag(tag);

    expect(node.hasTag(tag), isTrue);

    node.reset();

    expect(node.hasTag(tag), isFalse);
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
