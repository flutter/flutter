// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';


void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

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
        ..isSemanticBoundary = true
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

    test('after markNeedsSemanticsUpdate() all render objects between two semantic boundaries are asked for annotations', () {
      renderer.pipelineOwner.ensureSemantics();

      TestRender middle;
      final TestRender root = new TestRender(
        hasTapAction: true,
        isSemanticBoundary: true,
        child: new TestRender(
          hasLongPressAction: true,
          isSemanticBoundary: false,
          child: middle = new TestRender(
            hasScrollLeftAction: true,
            isSemanticBoundary: false,
            child: new TestRender(
              hasScrollRightAction: true,
              isSemanticBoundary: false,
              child: new TestRender(
                hasScrollUpAction: true,
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

      middle
        ..hasScrollLeftAction = false
        ..hasScrollDownAction = true;
      middle.markNeedsSemanticsUpdate();

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
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.geometricOrder),
      'SemanticsNode#3\n'
      ' │ STALE\n'
      ' │ owner: null\n'
      ' │ Rect.fromLTRB(0.0, 0.0, 10.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#1\n'
      ' │   STALE\n'
      ' │   owner: null\n'
      ' │   Rect.fromLTRB(0.0, 0.0, 5.0, 5.0)\n'
      ' │\n'
      ' └─SemanticsNode#2\n'
      '     STALE\n'
      '     owner: null\n'
      '     Rect.fromLTRB(5.0, 0.0, 10.0, 5.0)\n'
    );
  });

  test('OrdinalSortKey compares correctly', () {
    final List<List<SemanticsSortKey>> tests = <List<SemanticsSortKey>>[
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const OrdinalSortKey(0.0)],
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const OrdinalSortKey(1.0)],
      <SemanticsSortKey>[const OrdinalSortKey(1.0), const OrdinalSortKey(0.0)],
      <SemanticsSortKey>[const OrdinalSortKey(1.0), const OrdinalSortKey(1.0)],
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const CustomSortKey(1.0)],
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const CustomSortKey(0.0)],
      <SemanticsSortKey>[const CustomSortKey(0.0), const OrdinalSortKey(0.0)],
      <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(0.0)],
    ];
    final List<int> expectedResults = <int>[0, -1, 1, 0, 0, 0, 0, 0];
    assert(tests.length == expectedResults.length);
    final List<int> results = <int>[];
    for (List<SemanticsSortKey> tuple in tests) {
      results.add(tuple[0].compareTo(tuple[1]));
    }
    expect(results, orderedEquals(expectedResults));
  });

  test('SemanticsSortOrder sorts correctly', () {
    final SemanticsSortOrder order1 = new SemanticsSortOrder(key: const CustomSortKey(0.0));
    final SemanticsSortOrder order2 = new SemanticsSortOrder(key: const CustomSortKey(0.0));
    // Equal single keys compare equal.
    expect(order1.compareTo(order2), equals(0));
    // Key lists that are longer compare as after the shorter ones.
    order1.keys.add(const OrdinalSortKey(1.0));
    expect(order1.compareTo(order2), equals(1));
    // Equal multiple key lists compare equal.
    order2.keys.add(const OrdinalSortKey(1.0));
    expect(order1.compareTo(order2), equals(0));
    // Different types compare equal.
    order1.keys.add(const OrdinalSortKey(1.0));
    order2.keys.add(const CustomSortKey(1.0));
    expect(order1.compareTo(order2), equals(0));
    // Unequal multiple-key lists sort the shorter list first.
    order1.keys.add(const CustomSortKey(2.0));
    expect(order1.compareTo(order2), equals(1));
  });

  test('SemanticsSortOrder sorts correctly when assigned names', () {
    final SemanticsSortOrder order1g1 = new SemanticsSortOrder(key: const CustomSortKey(0.0, name: 'group 1'));
    final SemanticsSortOrder order2g1 = new SemanticsSortOrder(key: const CustomSortKey(1.0, name: 'group 1'));
    final SemanticsSortOrder order2g2 = new SemanticsSortOrder(key: const CustomSortKey(1.0, name: 'group 2'));
    final SemanticsSortOrder order3g2 = new SemanticsSortOrder(key: const OrdinalSortKey(1.0, name: 'group 1'));
    // Keys in the same group compare.
    expect(order1g1.compareTo(order2g1), equals(-1));
    // Keys with different names compare equal.
    expect(order1g1.compareTo(order2g2), equals(0));
    // Keys with same names but different types compare equal.
    expect(order1g1.compareTo(order3g2), equals(0));
  });

  test('SemanticsSortOrder replaces correctly in merge', () {
    final SemanticsSortOrder order1 = new SemanticsSortOrder(keys: <SemanticsSortKey>[const CustomSortKey(0.0), const OrdinalSortKey(0.0)]);
    final SemanticsSortOrder order2 = new SemanticsSortOrder(keys: <SemanticsSortKey>[const CustomSortKey(0.0), const OrdinalSortKey(0.0)]);
    final SemanticsSortOrder order3 = new SemanticsSortOrder(keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(1.0)], discardParentOrder: true);
    // Equal single keys compare equal.
    expect(order1.compareTo(order2), equals(0));
    // Merged orders with one that replaces merge correctly.
    final SemanticsSortOrder merged = order1.merge(order3);
    expect(merged.keys.length, 2);
    expect(merged.keys, orderedEquals(order3.keys));
    expect(merged.compareTo(order2), 1);
    // Merged orders with one that doesn't replace merge correctly.
    final SemanticsSortOrder merged2 = order1.merge(order2);
    expect(merged2.keys.length, 4);
    expect(merged2.keys, orderedEquals(<SemanticsSortKey>[]..addAll(order1.keys)..addAll(order2.keys)));
    expect(merged2.compareTo(order2), 1); // (merged2 is longer, so greater than).
  });

  test('OrdinalSortKey compares correctly', () {
    final List<List<SemanticsSortKey>> tests = <List<SemanticsSortKey>>[
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const OrdinalSortKey(0.0)],
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const OrdinalSortKey(1.0)],
      <SemanticsSortKey>[const OrdinalSortKey(1.0), const OrdinalSortKey(0.0)],
      <SemanticsSortKey>[const OrdinalSortKey(1.0), const OrdinalSortKey(1.0)],
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const CustomSortKey(1.0)],
      <SemanticsSortKey>[const OrdinalSortKey(0.0), const CustomSortKey(0.0)],
      <SemanticsSortKey>[const CustomSortKey(0.0), const OrdinalSortKey(0.0)],
      <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(0.0)],
    ];
    final List<int> expectedResults = <int>[0, -1, 1, 0, 0, 0, 0, 0];
    assert(tests.length == expectedResults.length);
    final List<int> results = <int>[];
    for (List<SemanticsSortKey> tuple in tests) {
      results.add(tuple[0].compareTo(tuple[1]));
    }
    expect(results, orderedEquals(expectedResults));
  });

  test('SemanticsSortOrder sorts correctly', () {
    final SemanticsSortOrder order1 = new SemanticsSortOrder(key: const CustomSortKey(0.0));
    final SemanticsSortOrder order2 = new SemanticsSortOrder(key: const CustomSortKey(0.0));
    // Equal single keys compare equal.
    expect(order1.compareTo(order2), equals(0));
    // Key lists that are longer compare as after the shorter ones.
    order1.keys.add(const OrdinalSortKey(1.0));
    expect(order1.compareTo(order2), equals(1));
    // Equal multiple key lists compare equal.
    order2.keys.add(const OrdinalSortKey(1.0));
    expect(order1.compareTo(order2), equals(0));
    // Different types compare equal.
    order1.keys.add(const OrdinalSortKey(1.0));
    order2.keys.add(const CustomSortKey(1.0));
    expect(order1.compareTo(order2), equals(0));
    // Unequal multiple-key lists sort the shorter list first.
    order1.keys.add(const CustomSortKey(2.0));
    expect(order1.compareTo(order2), equals(1));
  });

  test('SemanticsSortOrder sorts correctly when assigned names', () {
    final SemanticsSortOrder order1g1 = new SemanticsSortOrder(key: const CustomSortKey(0.0, name: 'group 1'));
    final SemanticsSortOrder order2g1 = new SemanticsSortOrder(key: const CustomSortKey(1.0, name: 'group 1'));
    final SemanticsSortOrder order2g2 = new SemanticsSortOrder(key: const CustomSortKey(1.0, name: 'group 2'));
    final SemanticsSortOrder order3g2 = new SemanticsSortOrder(key: const OrdinalSortKey(1.0, name: 'group 1'));
    // Keys in the same group compare.
    expect(order1g1.compareTo(order2g1), equals(-1));
    // Keys with different names compare equal.
    expect(order1g1.compareTo(order2g2), equals(0));
    // Keys with same names but different types compare equal.
    expect(order1g1.compareTo(order3g2), equals(0));
  });

  test('SemanticsSortOrder replaces correctly in merge', () {
    final SemanticsSortOrder order1 = new SemanticsSortOrder(keys: <SemanticsSortKey>[const CustomSortKey(0.0), const OrdinalSortKey(0.0)]);
    final SemanticsSortOrder order2 = new SemanticsSortOrder(keys: <SemanticsSortKey>[const CustomSortKey(0.0), const OrdinalSortKey(0.0)]);
    final SemanticsSortOrder order3 = new SemanticsSortOrder(keys: <SemanticsSortKey>[const CustomSortKey(1.0), const OrdinalSortKey(1.0)], discardParentOrder: true);
    // Equal single keys compare equal.
    expect(order1.compareTo(order2), equals(0));
    // Merged orders with one that replaces merge correctly.
    final SemanticsSortOrder merged = order1.merge(order3);
    expect(merged.keys.length, 2);
    expect(merged.keys, orderedEquals(order3.keys));
    expect(merged.compareTo(order2), 1);
    // Merged orders with one that doesn't replace merge correctly.
    final SemanticsSortOrder merged2 = order1.merge(order2);
    expect(merged2.keys.length, 4);
    expect(merged2.keys, orderedEquals(<SemanticsSortKey>[]..addAll(order1.keys)..addAll(order2.keys)));
    expect(merged2.compareTo(order2), 1); // (merged2 is longer, so greater than).
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
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.geometricOrder),
      'SemanticsNode#3\n'
      ' │ STALE\n'
      ' │ owner: null\n'
      ' │ Rect.fromLTRB(0.0, 0.0, 20.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#2\n'
      ' │   STALE\n'
      ' │   owner: null\n'
      ' │   Rect.fromLTRB(10.0, 0.0, 15.0, 5.0)\n'
      ' │\n'
      ' └─SemanticsNode#1\n'
      '     STALE\n'
      '     owner: null\n'
      '     Rect.fromLTRB(15.0, 0.0, 20.0, 5.0)\n'
    );

    expect(
      root.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest),
      'SemanticsNode#3\n'
      ' │ STALE\n'
      ' │ owner: null\n'
      ' │ Rect.fromLTRB(0.0, 0.0, 20.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#1\n'
      ' │   STALE\n'
      ' │   owner: null\n'
      ' │   Rect.fromLTRB(15.0, 0.0, 20.0, 5.0)\n'
      ' │\n'
      ' └─SemanticsNode#2\n'
      '     STALE\n'
      '     owner: null\n'
      '     Rect.fromLTRB(10.0, 0.0, 15.0, 5.0)\n'
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
      rootComplex.toStringDeep(childOrder: DebugSemanticsDumpOrder.geometricOrder),
      'SemanticsNode#7\n'
      ' │ STALE\n'
      ' │ owner: null\n'
      ' │ Rect.fromLTRB(0.0, 0.0, 25.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#4\n'
      ' │ │ STALE\n'
      ' │ │ owner: null\n'
      ' │ │ Rect.fromLTRB(0.0, 0.0, 10.0, 5.0)\n'
      ' │ │\n'
      ' │ ├─SemanticsNode#6\n'
      ' │ │   STALE\n'
      ' │ │   owner: null\n'
      ' │ │   Rect.fromLTRB(0.0, 0.0, 5.0, 5.0)\n'
      ' │ │\n'
      ' │ └─SemanticsNode#5\n'
      ' │     STALE\n'
      ' │     owner: null\n'
      ' │     Rect.fromLTRB(5.0, 0.0, 10.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#2\n'
      ' │   STALE\n'
      ' │   owner: null\n'
      ' │   Rect.fromLTRB(10.0, 0.0, 15.0, 5.0)\n'
      ' │\n'
      ' └─SemanticsNode#1\n'
      '     STALE\n'
      '     owner: null\n'
      '     Rect.fromLTRB(15.0, 0.0, 20.0, 5.0)\n'
    );

    expect(
      rootComplex.toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest),
      'SemanticsNode#7\n'
      ' │ STALE\n'
      ' │ owner: null\n'
      ' │ Rect.fromLTRB(0.0, 0.0, 25.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#1\n'
      ' │   STALE\n'
      ' │   owner: null\n'
      ' │   Rect.fromLTRB(15.0, 0.0, 20.0, 5.0)\n'
      ' │\n'
      ' ├─SemanticsNode#2\n'
      ' │   STALE\n'
      ' │   owner: null\n'
      ' │   Rect.fromLTRB(10.0, 0.0, 15.0, 5.0)\n'
      ' │\n'
      ' └─SemanticsNode#4\n'
      '   │ STALE\n'
      '   │ owner: null\n'
      '   │ Rect.fromLTRB(0.0, 0.0, 10.0, 5.0)\n'
      '   │\n'
      '   ├─SemanticsNode#5\n'
      '   │   STALE\n'
      '   │   owner: null\n'
      '   │   Rect.fromLTRB(5.0, 0.0, 10.0, 5.0)\n'
      '   │\n'
      '   └─SemanticsNode#6\n'
      '       STALE\n'
      '       owner: null\n'
      '       Rect.fromLTRB(0.0, 0.0, 5.0, 5.0)\n'
    );
  });

  test('debug properties', () {
    final SemanticsNode minimalProperties = new SemanticsNode();
    expect(
      minimalProperties.toStringDeep(),
      'SemanticsNode#1\n'
      '   Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)\n'
      '   invisible\n'
    );

    expect(
      minimalProperties.toStringDeep(minLevel: DiagnosticLevel.hidden),
      'SemanticsNode#1\n'
      '   owner: null\n'
      '   isMergedIntoParent: false\n'
      '   mergeAllDescendantsIntoThisNode: false\n'
      '   Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)\n'
      '   actions: []\n'
      '   flags: []\n'
      '   invisible\n'
      '   label: ""\n'
      '   value: ""\n'
      '   increasedValue: ""\n'
      '   decreasedValue: ""\n'
      '   hint: ""\n'
      '   textDirection: null\n'
      '   nextNodeId: null\n'
      '   previousNodeId: null\n'
      '   sortOrder: null\n'
      '   scrollExtentMin: null\n'
      '   scrollPosition: null\n'
      '   scrollExtentMax: null\n'
    );

    final SemanticsConfiguration config = new SemanticsConfiguration()
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true
      ..onScrollUp = () { }
      ..onLongPress = () { }
      ..onShowOnScreen = () { }
      ..isChecked = false
      ..isSelected = true
      ..isButton = true
      ..label = 'Use all the properties'
      ..textDirection = TextDirection.rtl
      ..sortOrder = new SemanticsSortOrder(keys: <SemanticsSortKey>[const OrdinalSortKey(1.0)]);
    final SemanticsNode allProperties = new SemanticsNode()
      ..rect = new Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = new Matrix4.translation(new Vector3(10.0, 10.0, 0.0))
      ..updateWith(config: config, childrenInInversePaintOrder: null);
    expect(
      allProperties.toStringDeep(),
      equalsIgnoringHashCodes(
          'SemanticsNode#2\n'
          '   STALE\n'
          '   owner: null\n'
          '   merge boundary ⛔️\n'
          '   Rect.fromLTRB(60.0, 20.0, 80.0, 50.0)\n'
          '   actions: longPress, scrollUp, showOnScreen\n'
          '   flags: hasCheckedState, isSelected, isButton\n'
          '   label: "Use all the properties"\n'
          '   textDirection: rtl\n'
          '   sortOrder: SemanticsSortOrder#b555b(keys:\n'
          '     [OrdinalSortKey#19df5(order: 1.0)])\n'
      ),
    );
    expect(
      allProperties.getSemanticsData().toString(),
      'SemanticsData(Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), [1.0,0.0,0.0,10.0; 0.0,1.0,0.0,10.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0], actions: [longPress, scrollUp, showOnScreen], flags: [hasCheckedState, isSelected, isButton], label: "Use all the properties", textDirection: rtl)',
    );

    final SemanticsNode scaled = new SemanticsNode()
      ..rect = new Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = new Matrix4.diagonal3(new Vector3(10.0, 10.0, 1.0));
    expect(
      scaled.toStringDeep(),
      'SemanticsNode#3\n'
      '   STALE\n'
      '   owner: null\n'
      '   Rect.fromLTRB(50.0, 10.0, 70.0, 40.0) scaled by 10.0x\n',
    );
    expect(
      scaled.getSemanticsData().toString(),
      'SemanticsData(Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), [10.0,0.0,0.0,0.0; 0.0,10.0,0.0,0.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0])',
    );
  });

  test('SemanticsConfiguration getter/setter', () {
    final SemanticsConfiguration config = new SemanticsConfiguration();

    expect(config.isSemanticBoundary, isFalse);
    expect(config.isButton, isFalse);
    expect(config.isMergingSemanticsOfDescendants, isFalse);
    expect(config.isEnabled, null);
    expect(config.isChecked, null);
    expect(config.isSelected, isFalse);
    expect(config.isBlockingSemanticsOfPreviouslyPaintedNodes, isFalse);
    expect(config.isFocused, isFalse);
    expect(config.isTextField, isFalse);

    expect(config.onShowOnScreen, isNull);
    expect(config.onScrollDown, isNull);
    expect(config.onScrollUp, isNull);
    expect(config.onScrollLeft, isNull);
    expect(config.onScrollRight, isNull);
    expect(config.onLongPress, isNull);
    expect(config.onDecrease, isNull);
    expect(config.onIncrease, isNull);
    expect(config.onMoveCursorForwardByCharacter, isNull);
    expect(config.onMoveCursorBackwardByCharacter, isNull);
    expect(config.onTap, isNull);

    config.isSemanticBoundary = true;
    config.isButton = true;
    config.isMergingSemanticsOfDescendants = true;
    config.isEnabled = true;
    config.isChecked = true;
    config.isSelected = true;
    config.isBlockingSemanticsOfPreviouslyPaintedNodes = true;
    config.isFocused = true;
    config.isTextField = true;

    final VoidCallback onShowOnScreen = () { };
    final VoidCallback onScrollDown = () { };
    final VoidCallback onScrollUp = () { };
    final VoidCallback onScrollLeft = () { };
    final VoidCallback onScrollRight = () { };
    final VoidCallback onLongPress = () { };
    final VoidCallback onDecrease = () { };
    final VoidCallback onIncrease = () { };
    final MoveCursorHandler onMoveCursorForwardByCharacter = (bool _) { };
    final MoveCursorHandler onMoveCursorBackwardByCharacter = (bool _) { };
    final VoidCallback onTap = () { };

    config.onShowOnScreen = onShowOnScreen;
    config.onScrollDown = onScrollDown;
    config.onScrollUp = onScrollUp;
    config.onScrollLeft = onScrollLeft;
    config.onScrollRight = onScrollRight;
    config.onLongPress = onLongPress;
    config.onDecrease = onDecrease;
    config.onIncrease = onIncrease;
    config.onMoveCursorForwardByCharacter = onMoveCursorForwardByCharacter;
    config.onMoveCursorBackwardByCharacter = onMoveCursorBackwardByCharacter;
    config.onTap = onTap;

    expect(config.isSemanticBoundary, isTrue);
    expect(config.isButton, isTrue);
    expect(config.isMergingSemanticsOfDescendants, isTrue);
    expect(config.isEnabled, isTrue);
    expect(config.isChecked, isTrue);
    expect(config.isSelected, isTrue);
    expect(config.isBlockingSemanticsOfPreviouslyPaintedNodes, isTrue);
    expect(config.isFocused, isTrue);
    expect(config.isTextField, isTrue);

    expect(config.onShowOnScreen, same(onShowOnScreen));
    expect(config.onScrollDown, same(onScrollDown));
    expect(config.onScrollUp, same(onScrollUp));
    expect(config.onScrollLeft, same(onScrollLeft));
    expect(config.onScrollRight, same(onScrollRight));
    expect(config.onLongPress, same(onLongPress));
    expect(config.onDecrease, same(onDecrease));
    expect(config.onIncrease, same(onIncrease));
    expect(config.onMoveCursorForwardByCharacter, same(onMoveCursorForwardByCharacter));
    expect(config.onMoveCursorBackwardByCharacter, same(onMoveCursorBackwardByCharacter));
    expect(config.onTap, same(onTap));
  });
}

class TestRender extends RenderProxyBox {

  TestRender({
    this.hasTapAction: false,
    this.hasLongPressAction: false,
    this.hasScrollLeftAction: false,
    this.hasScrollRightAction: false,
    this.hasScrollUpAction: false,
    this.hasScrollDownAction: false,
    this.isSemanticBoundary,
    RenderObject child
  }) : super(child);

  bool hasTapAction;
  bool hasLongPressAction;
  bool hasScrollLeftAction;
  bool hasScrollRightAction;
  bool hasScrollUpAction;
  bool hasScrollDownAction;
  bool isSemanticBoundary;


  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isSemanticBoundary = isSemanticBoundary;
    if (hasTapAction)
      config.onTap = () { };
    if (hasLongPressAction)
      config.onLongPress = () { };
    if (hasScrollLeftAction)
      config.onScrollLeft = () { };
    if (hasScrollRightAction)
      config.onScrollRight = () { };
    if (hasScrollUpAction)
      config.onScrollUp = () { };
    if (hasScrollDownAction)
      config.onScrollDown = () { };
  }
}

class CustomSortKey extends OrdinalSortKey {
  const CustomSortKey(double order, {String name}) : super(order, name: name);
}
