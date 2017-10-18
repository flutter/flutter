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

      expect(node.isTagged(tag1), isFalse);
      expect(node.isTagged(tag2), isFalse);

      node.tags = new Set<SemanticsTag>()..add(tag1);
      expect(node.isTagged(tag1), isTrue);
      expect(node.isTagged(tag2), isFalse);

      node.tags.add(tag2);
      expect(node.isTagged(tag1), isTrue);
      expect(node.isTagged(tag2), isTrue);
    });

    test('getSemanticsData includes tags', () {
      final Set<SemanticsTag> tags = new Set<SemanticsTag>()
        ..add(tag1)
        ..add(tag2);

      final SemanticsNode node = new SemanticsNode()
        ..rect = new Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ..tags = tags;

      expect(node.getSemanticsData().tags, tags);

      tags.add(tag3);

      final SemanticsConfiguration config = new SemanticsConfiguration()
        ..isMergingSemanticsOfDescendants = true;

      node.updateWith(
        config: config,
        childrenInInversePaintOrder: <SemanticsNode>[
          new SemanticsNode()
            ..isMergedIntoParent = true
            ..rect = new Rect.fromLTRB(5.0, 5.0, 10.0, 10.0)
            ..tags = tags,
        ],
      );

      expect(node.getSemanticsData().tags, tags);
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

      pumpFrame(phase: EnginePhase.flushSemantics);

      expectedActions = SemanticsAction.tap.index | SemanticsAction.longPress.index | SemanticsAction.scrollDown.index | SemanticsAction.scrollRight.index;
      expect(root.debugSemantics.getSemanticsData().actions, expectedActions);
    });
  });

  test('toStringDeep() does not throw with transform == null', () {
    final SemanticsNode child1 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(0.0, 0.0, 5.0, 5.0);
    final SemanticsNode child2 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(5.0, 0.0, 10.0, 5.0);
    final SemanticsNode root = new SemanticsNode()
      ..rect = new Rect.fromLTRB(0.0, 0.0, 10.0, 5.0);
    root.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[child1, child2],
    );

    expect(root.transform, isNull);
    expect(child1.transform, isNull);
    expect(child2.transform, isNull);

    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversal),
      'SemanticsNode#8(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 10.0, 5.0))\n'
      '├SemanticsNode#6(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 5.0, 5.0))\n'
      '└SemanticsNode#7(STALE, owner: null, Rect.fromLTRB(5.0, 0.0, 10.0, 5.0))\n',
    );
  });

  test('toStringDeep respects childOrder parameter', () {
    final SemanticsNode child1 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(15.0, 0.0, 20.0, 5.0);
    final SemanticsNode child2 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(10.0, 0.0, 15.0, 5.0);
    final SemanticsNode root = new SemanticsNode()
      ..rect = new Rect.fromLTRB(0.0, 0.0, 20.0, 5.0);
    root.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[child1, child2],
    );
    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversal),
      'SemanticsNode#11(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 20.0, 5.0))\n'
      '├SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 0.0, 15.0, 5.0))\n'
      '└SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(15.0, 0.0, 20.0, 5.0))\n',
    );

    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest),
      'SemanticsNode#11(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 20.0, 5.0))\n'
      '├SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(15.0, 0.0, 20.0, 5.0))\n'
      '└SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 0.0, 15.0, 5.0))\n',
    );

    final SemanticsNode child3 = new SemanticsNode()
      ..rect = new Rect.fromLTRB(0.0, 0.0, 10.0, 5.0);
    child3.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[
        new SemanticsNode()
          ..rect = new Rect.fromLTRB(5.0, 0.0, 10.0, 5.0),
        new SemanticsNode()
          ..rect = new Rect.fromLTRB(0.0, 0.0, 5.0, 5.0),
      ],
    );

    final SemanticsNode rootComplex = new SemanticsNode()
      ..rect = new Rect.fromLTRB(0.0, 0.0, 25.0, 5.0);
    rootComplex.updateWith(
        config: null,
        childrenInInversePaintOrder: <SemanticsNode>[child1, child2, child3]
    );

    expect(
      rootComplex.toStringDeep(childOrder: DebugSemanticsDumpOrder.traversal),
      'SemanticsNode#15(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 25.0, 5.0))\n'
      '├SemanticsNode#12(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 10.0, 5.0))\n'
      '│├SemanticsNode#14(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 5.0, 5.0))\n'
      '│└SemanticsNode#13(STALE, owner: null, Rect.fromLTRB(5.0, 0.0, 10.0, 5.0))\n'
      '├SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 0.0, 15.0, 5.0))\n'
      '└SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(15.0, 0.0, 20.0, 5.0))\n',
    );

    expect(
      rootComplex.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest),
      'SemanticsNode#15(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 25.0, 5.0))\n'
      '├SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(15.0, 0.0, 20.0, 5.0))\n'
      '├SemanticsNode#10(STALE, owner: null, Rect.fromLTRB(10.0, 0.0, 15.0, 5.0))\n'
      '└SemanticsNode#12(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 10.0, 5.0))\n'
      ' ├SemanticsNode#13(STALE, owner: null, Rect.fromLTRB(5.0, 0.0, 10.0, 5.0))\n'
      ' └SemanticsNode#14(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 5.0, 5.0))\n',
    );
  });

  test('debug properties', () {
    final SemanticsNode minimalProperties = new SemanticsNode();
    expect(
      minimalProperties.toStringDeep(),
      'SemanticsNode#16(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0))\n',
    );

    expect(
      minimalProperties.toStringDeep(minLevel: DiagnosticLevel.hidden),
      'SemanticsNode#16(owner: null, isPartOfNodeMerging: false, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), wasAffectedByClip: false, actions: [], isSelected: false, label: "", textDirection: null)\n',
    );

    final SemanticsConfiguration config = new SemanticsConfiguration()
      ..isMergingSemanticsOfDescendants = true
      ..addAction(SemanticsAction.scrollUp, () { })
      ..addAction(SemanticsAction.longPress, () { })
      ..addAction(SemanticsAction.showOnScreen, () { })
      ..isChecked = false
      ..isSelected = true
      ..label = "Use all the properties"
      ..textDirection = TextDirection.rtl;
    final SemanticsNode allProperties = new SemanticsNode()
      ..rect = new Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = new Matrix4.translation(new Vector3(10.0, 10.0, 0.0))
      ..wasAffectedByClip = true
      ..updateWith(config: config, childrenInInversePaintOrder: null);
    expect(
      allProperties.toStringDeep(),
      'SemanticsNode#17(STALE, owner: null, leaf merge, Rect.fromLTRB(60.0, 20.0, 80.0, 50.0), clipped, actions: [longPress, scrollUp, showOnScreen], unchecked, selected, label: "Use all the properties", textDirection: rtl)\n',
    );
    expect(
      allProperties.getSemanticsData().toString(),
      'SemanticsData(Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), [1.0,0.0,0.0,10.0; 0.0,1.0,0.0,10.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0], actions: [longPress, scrollUp, showOnScreen], flags: [hasCheckedState, isSelected], label: "Use all the properties", textDirection: rtl)',
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
}

class TestRender extends RenderProxyBox {

  TestRender({ this.action, this.isSemanticBoundary, RenderObject child }) : super(child);

  final bool isSemanticBoundary;

  SemanticsAction action;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config
      ..isSemanticBoundary = isSemanticBoundary
      ..addAction(action, () { });
  }
}
