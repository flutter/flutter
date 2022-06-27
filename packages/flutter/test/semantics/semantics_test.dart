// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import '../rendering/rendering_tester.dart';

const int kMaxFrameworkAccessibilityIdentifier = (1<<16) - 1;

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  group('SemanticsNode', () {
    const SemanticsTag tag1 = SemanticsTag('Tag One');
    const SemanticsTag tag2 = SemanticsTag('Tag Two');
    const SemanticsTag tag3 = SemanticsTag('Tag Three');

    test('tagging', () {
      final SemanticsNode node = SemanticsNode();

      expect(node.isTagged(tag1), isFalse);
      expect(node.isTagged(tag2), isFalse);

      node.tags = <SemanticsTag>{tag1};
      expect(node.isTagged(tag1), isTrue);
      expect(node.isTagged(tag2), isFalse);

      node.tags!.add(tag2);
      expect(node.isTagged(tag1), isTrue);
      expect(node.isTagged(tag2), isTrue);
    });

    test('getSemanticsData includes tags', () {
      final Set<SemanticsTag> tags = <SemanticsTag>{tag1, tag2};

      final SemanticsNode node = SemanticsNode()
        ..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ..tags = tags;

      expect(node.getSemanticsData().tags, tags);

      tags.add(tag3);

      final SemanticsConfiguration config = SemanticsConfiguration()
        ..isSemanticBoundary = true
        ..isMergingSemanticsOfDescendants = true;

      node.updateWith(
        config: config,
        childrenInInversePaintOrder: <SemanticsNode>[
          SemanticsNode()
            ..isMergedIntoParent = true
            ..rect = const Rect.fromLTRB(5.0, 5.0, 10.0, 10.0)
            ..tags = tags,
        ],
      );

      expect(node.getSemanticsData().tags, tags);
    });

    test('SemanticsConfiguration can set both string label/value/hint and attributed version', () {
      final SemanticsConfiguration config = SemanticsConfiguration();
      config.label = 'label1';
      expect(config.label, 'label1');
      expect(config.attributedLabel.string, 'label1');
      expect(config.attributedLabel.attributes.isEmpty, isTrue);
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#1(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label1")',
      );

      config.attributedLabel = AttributedString(
        'label2',
        attributes: <StringAttribute>[
          SpellOutStringAttribute(range: const TextRange(start: 0, end:1)),
        ]
      );
      expect(config.label, 'label2');
      expect(config.attributedLabel.string, 'label2');
      expect(config.attributedLabel.attributes.length, 1);
      expect(config.attributedLabel.attributes[0] is SpellOutStringAttribute, isTrue);
      expect(config.attributedLabel.attributes[0].range, const TextRange(start: 0, end: 1));
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#2(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label2" [SpellOutStringAttribute(TextRange(start: 0, end: 1))])',
      );

      config.label = 'label3';
      expect(config.label, 'label3');
      expect(config.attributedLabel.string, 'label3');
      expect(config.attributedLabel.attributes.isEmpty, isTrue);
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#3(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3")',
      );

      config.value = 'value1';
      expect(config.value, 'value1');
      expect(config.attributedValue.string, 'value1');
      expect(config.attributedValue.attributes.isEmpty, isTrue);
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#4(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3", value: "value1")',
      );

      config.attributedValue = AttributedString(
          'value2',
          attributes: <StringAttribute>[
            SpellOutStringAttribute(range: const TextRange(start: 0, end:1)),
          ]
      );
      expect(config.value, 'value2');
      expect(config.attributedValue.string, 'value2');
      expect(config.attributedValue.attributes.length, 1);
      expect(config.attributedValue.attributes[0] is SpellOutStringAttribute, isTrue);
      expect(config.attributedValue.attributes[0].range, const TextRange(start: 0, end: 1));
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#5(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3", value: "value2" [SpellOutStringAttribute(TextRange(start: 0, end: 1))])',
      );

      config.value = 'value3';
      expect(config.value, 'value3');
      expect(config.attributedValue.string, 'value3');
      expect(config.attributedValue.attributes.isEmpty, isTrue);
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#6(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3", value: "value3")',
      );

      config.hint = 'hint1';
      expect(config.hint, 'hint1');
      expect(config.attributedHint.string, 'hint1');
      expect(config.attributedHint.attributes.isEmpty, isTrue);
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#7(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3", value: "value3", hint: "hint1")',
      );

      config.attributedHint = AttributedString(
          'hint2',
          attributes: <StringAttribute>[
            SpellOutStringAttribute(range: const TextRange(start: 0, end:1)),
          ]
      );
      expect(config.hint, 'hint2');
      expect(config.attributedHint.string, 'hint2');
      expect(config.attributedHint.attributes.length, 1);
      expect(config.attributedHint.attributes[0] is SpellOutStringAttribute, isTrue);
      expect(config.attributedHint.attributes[0].range, const TextRange(start: 0, end: 1));
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#8(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3", value: "value3", hint: "hint2" [SpellOutStringAttribute(TextRange(start: 0, end: 1))])',
      );

      config.hint = 'hint3';
      expect(config.hint, 'hint3');
      expect(config.attributedHint.string, 'hint3');
      expect(config.attributedHint.attributes.isEmpty, isTrue);
      expect(
        (SemanticsNode()..updateWith(config: config)).toString(),
        'SemanticsNode#9(STALE, owner: null, Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible, label: "label3", value: "value3", hint: "hint3")',
      );
    });

    test('mutate existing semantic node list errors', () {
      final SemanticsNode node = SemanticsNode()
        ..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);

      final SemanticsConfiguration config = SemanticsConfiguration()
        ..isSemanticBoundary = true
        ..isMergingSemanticsOfDescendants = true;

      final List<SemanticsNode> children = <SemanticsNode>[
        SemanticsNode()
          ..isMergedIntoParent = true
          ..rect = const Rect.fromLTRB(5.0, 5.0, 10.0, 10.0),
      ];

      node.updateWith(
        config: config,
        childrenInInversePaintOrder: children,
      );

      children.add(
        SemanticsNode()
          ..isMergedIntoParent = true
          ..rect = const Rect.fromLTRB(42.0, 42.0, 10.0, 10.0),
      );

      {
        late FlutterError error;
        try {
          node.updateWith(
            config: config,
            childrenInInversePaintOrder: children,
          );
        } on FlutterError catch (e) {
          error = e;
        }
        expect(error.toString(), equalsIgnoringHashCodes(
          'Failed to replace child semantics nodes because the list of `SemanticsNode`s was mutated.\n'
          'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.\n'
          'Error details:\n'
          "The list's length has changed from 1 to 2.",
        ));
        expect(
          error.diagnostics.singleWhere((DiagnosticsNode node) => node.level == DiagnosticLevel.hint).toString(),
          'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.',
        );
      }

      {
        late FlutterError error;
        final List<SemanticsNode> modifiedChildren = <SemanticsNode>[
          SemanticsNode()
            ..isMergedIntoParent = true
            ..rect = const Rect.fromLTRB(5.0, 5.0, 10.0, 10.0),
          SemanticsNode()
            ..isMergedIntoParent = true
            ..rect = const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0),
        ];
        node.updateWith(
          config: config,
          childrenInInversePaintOrder: modifiedChildren,
        );
        try {
          modifiedChildren[0] = SemanticsNode()
            ..isMergedIntoParent = true
            ..rect = const Rect.fromLTRB(0.0, 0.0, 20.0, 20.0);
          modifiedChildren[1] = SemanticsNode()
            ..isMergedIntoParent = true
            ..rect = const Rect.fromLTRB(40.0, 14.0, 20.0, 20.0);
          node.updateWith(
            config: config,
            childrenInInversePaintOrder: modifiedChildren,
          );
        } on FlutterError catch (e) {
          error = e;
        }
        expect(error.toStringDeep(), equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Failed to replace child semantics nodes because the list of\n'
          '   `SemanticsNode`s was mutated.\n'
          '   Instead of mutating the existing list, create a new list\n'
          '   containing the desired `SemanticsNode`s.\n'
          '   Error details:\n'
          '   Child node at position 0 was replaced:\n'
          '   Previous child: SemanticsNode#6(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(0.0, 0.0, 20.0, 20.0))\n'
          '   New child: SemanticsNode#4(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(5.0, 5.0, 10.0, 10.0))\n'
          '\n'
          '   Child node at position 1 was replaced:\n'
          '   Previous child: SemanticsNode#7(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(40.0, 14.0, 20.0, 20.0))\n'
          '   New child: SemanticsNode#5(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(10.0, 10.0, 20.0, 20.0))\n',
        ));

        expect(
          error.diagnostics.singleWhere((DiagnosticsNode node) => node.level == DiagnosticLevel.hint).toString(),
          'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.',
        );
        // Two previous children and two new children.
        expect(error.diagnostics.where((DiagnosticsNode node) => node.value is SemanticsNode).length, 4);
      }
    });

    test('after markNeedsSemanticsUpdate() all render objects between two semantic boundaries are asked for annotations', () {
      TestRenderingFlutterBinding.instance.pipelineOwner.ensureSemantics();

      TestRender middle;
      final TestRender root = TestRender(
        hasTapAction: true,
        isSemanticBoundary: true,
        child: TestRender(
          hasLongPressAction: true,
          child: middle = TestRender(
            hasScrollLeftAction: true,
            child: TestRender(
              hasScrollRightAction: true,
              child: TestRender(
                hasScrollUpAction: true,
                isSemanticBoundary: true,
              ),
            ),
          ),
        ),
      );

      layout(root);
      pumpFrame(phase: EnginePhase.flushSemantics);

      int expectedActions = SemanticsAction.tap.index | SemanticsAction.longPress.index | SemanticsAction.scrollLeft.index | SemanticsAction.scrollRight.index;
      expect(root.debugSemantics!.getSemanticsData().actions, expectedActions);

      middle
        ..hasScrollLeftAction = false
        ..hasScrollDownAction = true;
      middle.markNeedsSemanticsUpdate();

      pumpFrame(phase: EnginePhase.flushSemantics);

      expectedActions = SemanticsAction.tap.index | SemanticsAction.longPress.index | SemanticsAction.scrollDown.index | SemanticsAction.scrollRight.index;
      expect(root.debugSemantics!.getSemanticsData().actions, expectedActions);
    });
  });

  test('toStringDeep() does not throw with transform == null', () {
    final SemanticsNode child1 = SemanticsNode()
      ..rect = const Rect.fromLTRB(0.0, 0.0, 5.0, 5.0);
    final SemanticsNode child2 = SemanticsNode()
      ..rect = const Rect.fromLTRB(5.0, 0.0, 10.0, 5.0);
    final SemanticsNode root = SemanticsNode()
      ..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 5.0);
    root.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[child1, child2],
    );

    expect(root.transform, isNull);
    expect(child1.transform, isNull);
    expect(child2.transform, isNull);

    expect(
      root.toStringDeep(),
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
      '     Rect.fromLTRB(5.0, 0.0, 10.0, 5.0)\n',
    );
  });

  test('Incompatible OrdinalSortKey throw AssertionError when compared', () {
    // Different types.
    expect(() {
      const OrdinalSortKey(0.0).compareTo(const CustomSortKey(0.0));
    }, throwsAssertionError);
  });

  test('OrdinalSortKey compares correctly when names are the same', () {
    const List<List<SemanticsSortKey>> tests = <List<SemanticsSortKey>>[
      <SemanticsSortKey>[OrdinalSortKey(0.0), OrdinalSortKey(0.0)],
      <SemanticsSortKey>[OrdinalSortKey(0.0), OrdinalSortKey(1.0)],
      <SemanticsSortKey>[OrdinalSortKey(1.0), OrdinalSortKey(0.0)],
      <SemanticsSortKey>[OrdinalSortKey(1.0), OrdinalSortKey(1.0)],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'a'), OrdinalSortKey(0.0, name: 'a')],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'a'), OrdinalSortKey(1.0, name: 'a')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'a'), OrdinalSortKey(0.0, name: 'a')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'a'), OrdinalSortKey(1.0, name: 'a')],
    ];
    final List<int> expectedResults = <int>[0, -1, 1, 0, 0, -1, 1, 0];
    assert(tests.length == expectedResults.length);
    final List<int> results = <int>[
      for (final List<SemanticsSortKey> tuple in tests) tuple[0].compareTo(tuple[1]),
    ];
    expect(results, orderedEquals(expectedResults));

    // Differing types should throw an assertion.
    expect(() => const OrdinalSortKey(0.0).compareTo(const CustomSortKey(0.0)), throwsAssertionError);
  });

  test('OrdinalSortKey compares correctly when the names are different', () {
    const List<List<SemanticsSortKey>> tests = <List<SemanticsSortKey>>[
      <SemanticsSortKey>[OrdinalSortKey(0.0), OrdinalSortKey(0.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(0.0), OrdinalSortKey(1.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(1.0), OrdinalSortKey(0.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(1.0), OrdinalSortKey(1.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'foo'), OrdinalSortKey(0.0)],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'foo'), OrdinalSortKey(1.0)],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'foo'), OrdinalSortKey(0.0)],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'foo'), OrdinalSortKey(1.0)],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'foo'), OrdinalSortKey(0.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'foo'), OrdinalSortKey(1.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'foo'), OrdinalSortKey(0.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'foo'), OrdinalSortKey(1.0, name: 'bar')],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'bar'), OrdinalSortKey(0.0, name: 'foo')],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'bar'), OrdinalSortKey(1.0, name: 'foo')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'bar'), OrdinalSortKey(0.0, name: 'foo')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'bar'), OrdinalSortKey(1.0, name: 'foo')],
    ];
    final List<int> expectedResults = <int>[ -1, -1, -1, -1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1];
    assert(tests.length == expectedResults.length);
    final List<int> results = <int>[
      for (final List<SemanticsSortKey> tuple in tests) tuple[0].compareTo(tuple[1]),
    ];
    expect(results, orderedEquals(expectedResults));
  });

  test('toStringDeep respects childOrder parameter', () {
    final SemanticsNode child1 = SemanticsNode()
      ..rect = const Rect.fromLTRB(15.0, 0.0, 20.0, 5.0);
    final SemanticsNode child2 = SemanticsNode()
      ..rect = const Rect.fromLTRB(10.0, 0.0, 15.0, 5.0);
    final SemanticsNode root = SemanticsNode()
      ..rect = const Rect.fromLTRB(0.0, 0.0, 20.0, 5.0);
    root.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[child1, child2],
    );
    expect(
      root.toStringDeep(),
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
      '     Rect.fromLTRB(10.0, 0.0, 15.0, 5.0)\n',
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
      '     Rect.fromLTRB(10.0, 0.0, 15.0, 5.0)\n',
    );

    final SemanticsNode child3 = SemanticsNode()
      ..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 5.0);
    child3.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[
        SemanticsNode()
          ..rect = const Rect.fromLTRB(5.0, 0.0, 10.0, 5.0),
        SemanticsNode()
          ..rect = const Rect.fromLTRB(0.0, 0.0, 5.0, 5.0),
      ],
    );

    final SemanticsNode rootComplex = SemanticsNode()
      ..rect = const Rect.fromLTRB(0.0, 0.0, 25.0, 5.0);
    rootComplex.updateWith(
        config: null,
        childrenInInversePaintOrder: <SemanticsNode>[child1, child2, child3],
    );

    expect(
      rootComplex.toStringDeep(),
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
      '       Rect.fromLTRB(0.0, 0.0, 5.0, 5.0)\n',
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
      '       Rect.fromLTRB(0.0, 0.0, 5.0, 5.0)\n',
    );
  });

  test('debug properties', () {
    final SemanticsNode minimalProperties = SemanticsNode();
    expect(
      minimalProperties.toStringDeep(),
      'SemanticsNode#1\n'
      '   Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)\n'
      '   invisible\n',
    );

    expect(
      minimalProperties.toStringDeep(minLevel: DiagnosticLevel.hidden),
      'SemanticsNode#1\n'
      '   owner: null\n'
      '   isMergedIntoParent: false\n'
      '   mergeAllDescendantsIntoThisNode: false\n'
      '   Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)\n'
      '   tags: null\n'
      '   actions: []\n'
      '   customActions: []\n'
      '   flags: []\n'
      '   invisible\n'
      '   isHidden: false\n'
      '   label: ""\n'
      '   value: ""\n'
      '   increasedValue: ""\n'
      '   decreasedValue: ""\n'
      '   hint: ""\n'
      '   tooltip: ""\n'
      '   textDirection: null\n'
      '   sortKey: null\n'
      '   platformViewId: null\n'
      '   maxValueLength: null\n'
      '   currentValueLength: null\n'
      '   scrollChildren: null\n'
      '   scrollIndex: null\n'
      '   scrollExtentMin: null\n'
      '   scrollPosition: null\n'
      '   scrollExtentMax: null\n'
      '   elevation: 0.0\n'
      '   thickness: 0.0\n',
    );

    final SemanticsConfiguration config = SemanticsConfiguration()
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
      ..sortKey = const OrdinalSortKey(1.0);
    final SemanticsNode allProperties = SemanticsNode()
      ..rect = const Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = Matrix4.translation(Vector3(10.0, 10.0, 0.0))
      ..updateWith(config: config);
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
        '   sortKey: OrdinalSortKey#19df5(order: 1.0)\n',
      ),
    );
    expect(
      allProperties.getSemanticsData().toString(),
      'SemanticsData(Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), [1.0,0.0,0.0,10.0; 0.0,1.0,0.0,10.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0], actions: [longPress, scrollUp, showOnScreen], flags: [hasCheckedState, isSelected, isButton], label: "Use all the properties", textDirection: rtl)',
    );

    final SemanticsNode scaled = SemanticsNode()
      ..rect = const Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = Matrix4.diagonal3(Vector3(10.0, 10.0, 1.0));
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

  test('Custom actions debug properties', () {
    final SemanticsConfiguration configuration = SemanticsConfiguration();
    const CustomSemanticsAction action1 = CustomSemanticsAction(label: 'action1');
    const CustomSemanticsAction action2 = CustomSemanticsAction(label: 'action2');
    const CustomSemanticsAction action3 = CustomSemanticsAction(label: 'action3');
    configuration.customSemanticsActions = <CustomSemanticsAction, VoidCallback>{
      action1: () { },
      action2: () { },
      action3: () { },
    };
    final SemanticsNode actionNode = SemanticsNode();
    actionNode.updateWith(config: configuration);

    expect(
      actionNode.toStringDeep(minLevel: DiagnosticLevel.hidden),
      'SemanticsNode#1\n'
      '   STALE\n'
      '   owner: null\n'
      '   isMergedIntoParent: false\n'
      '   mergeAllDescendantsIntoThisNode: false\n'
      '   Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)\n'
      '   tags: null\n'
      '   actions: customAction\n'
      '   customActions: action1, action2, action3\n'
      '   flags: []\n'
      '   invisible\n'
      '   isHidden: false\n'
      '   label: ""\n'
      '   value: ""\n'
      '   increasedValue: ""\n'
      '   decreasedValue: ""\n'
      '   hint: ""\n'
      '   tooltip: ""\n'
      '   textDirection: null\n'
      '   sortKey: null\n'
      '   platformViewId: null\n'
      '   maxValueLength: null\n'
      '   currentValueLength: null\n'
      '   scrollChildren: null\n'
      '   scrollIndex: null\n'
      '   scrollExtentMin: null\n'
      '   scrollPosition: null\n'
      '   scrollExtentMax: null\n'
      '   elevation: 0.0\n'
      '   thickness: 0.0\n',
    );
  });

  test('Attributed String can concate', () {
    final AttributedString string1 = AttributedString(
      'string1',
      attributes: <StringAttribute>[
        SpellOutStringAttribute(range: const TextRange(start:0, end:4)),
      ]
    );
    final AttributedString string2 = AttributedString(
        'string2',
        attributes: <StringAttribute>[
          LocaleStringAttribute(locale: const Locale('es', 'MX'), range: const TextRange(start:0, end:4)),
        ]
    );
    final AttributedString result = string1 + string2;
    expect(result.string, 'string1string2');
    expect(result.attributes.length, 2);
    expect(result.attributes[0].range, const TextRange(start:0, end:4));
    expect(result.attributes[0] is SpellOutStringAttribute, isTrue);
    expect(result.toString(), "AttributedString('string1string2', attributes: [SpellOutStringAttribute(TextRange(start: 0, end: 4)), LocaleStringAttribute(TextRange(start: 7, end: 11), es-MX)])");
  });

  test('Semantics id does not repeat', () {
    final SemanticsOwner owner = SemanticsOwner();
    const int expectId = 1400;
    SemanticsNode? nodeToRemove;
    for (int i = 0; i < kMaxFrameworkAccessibilityIdentifier; i++) {
      final SemanticsNode node = SemanticsNode();
      node.attach(owner);
      if (node.id == expectId) {
        nodeToRemove = node;
      }
    }
    nodeToRemove!.detach();
    final SemanticsNode newNode = SemanticsNode();
    newNode.attach(owner);
    // Id is reused.
    expect(newNode.id, expectId);
  });

  test('Tags show up in debug properties', () {
    final SemanticsNode actionNode = SemanticsNode()
      ..tags = <SemanticsTag>{RenderViewport.useTwoPaneSemantics};

    expect(
      actionNode.toStringDeep(),
      contains('\n   tags: RenderViewport.twoPane\n'),
    );
  });

  test('SemanticsConfiguration getter/setter', () {
    final SemanticsConfiguration config = SemanticsConfiguration();
    const CustomSemanticsAction customAction = CustomSemanticsAction(label: 'test');

    expect(config.isSemanticBoundary, isFalse);
    expect(config.isButton, isFalse);
    expect(config.isLink, isFalse);
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
    expect(config.customSemanticsActions[customAction], isNull);

    config.isSemanticBoundary = true;
    config.isButton = true;
    config.isLink = true;
    config.isMergingSemanticsOfDescendants = true;
    config.isEnabled = true;
    config.isChecked = true;
    config.isSelected = true;
    config.isBlockingSemanticsOfPreviouslyPaintedNodes = true;
    config.isFocused = true;
    config.isTextField = true;

    void onShowOnScreen() { }
    void onScrollDown() { }
    void onScrollUp() { }
    void onScrollLeft() { }
    void onScrollRight() { }
    void onLongPress() { }
    void onDecrease() { }
    void onIncrease() { }
    void onMoveCursorForwardByCharacter(bool _) { }
    void onMoveCursorBackwardByCharacter(bool _) { }
    void onTap() { }
    void onCustomAction() { }

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
    config.customSemanticsActions[customAction] = onCustomAction;

    expect(config.isSemanticBoundary, isTrue);
    expect(config.isButton, isTrue);
    expect(config.isLink, isTrue);
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
    expect(config.customSemanticsActions[customAction], same(onCustomAction));
  });
}

class TestRender extends RenderProxyBox {

  TestRender({
    this.hasTapAction = false,
    this.hasLongPressAction = false,
    this.hasScrollLeftAction = false,
    this.hasScrollRightAction = false,
    this.hasScrollUpAction = false,
    this.hasScrollDownAction = false,
    this.isSemanticBoundary = false,
    RenderBox? child,
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
    if (hasTapAction) {
      config.onTap = () { };
    }
    if (hasLongPressAction) {
      config.onLongPress = () { };
    }
    if (hasScrollLeftAction) {
      config.onScrollLeft = () { };
    }
    if (hasScrollRightAction) {
      config.onScrollRight = () { };
    }
    if (hasScrollUpAction) {
      config.onScrollUp = () { };
    }
    if (hasScrollDownAction) {
      config.onScrollDown = () { };
    }
  }
}

class CustomSortKey extends OrdinalSortKey {
  const CustomSortKey(super.order, {super.name});
}
