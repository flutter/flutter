// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:vector_math/vector_math_64.dart';

import '../rendering/rendering_tester.dart';

const int kMaxFrameworkAccessibilityIdentifier = (1 << 16) - 1;

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  group('SemanticsNode', () {
    const tag1 = SemanticsTag('Tag One');
    const tag2 = SemanticsTag('Tag Two');
    const tag3 = SemanticsTag('Tag Three');

    test('tagging', () {
      final node = SemanticsNode();

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
      final tags = <SemanticsTag>{tag1, tag2};

      final node = SemanticsNode()
        ..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ..tags = tags;

      expect(node.getSemanticsData().tags, tags);

      tags.add(tag3);

      final config = SemanticsConfiguration()
        ..isSemanticBoundary = true
        ..isMergingSemanticsOfDescendants = true;

      node.updateWith(
        config: config,
        childrenInInversePaintOrder: <SemanticsNode>[
          SemanticsNode()
            ..rect = const Rect.fromLTRB(5.0, 5.0, 10.0, 10.0)
            ..tags = tags,
        ],
      );

      expect(node.getSemanticsData().tags, tags);
    });

    test('SemanticsConfiguration can set both string label/value/hint and attributed version', () {
      final config = SemanticsConfiguration();
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
          SpellOutStringAttribute(range: const TextRange(start: 0, end: 1)),
        ],
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
          SpellOutStringAttribute(range: const TextRange(start: 0, end: 1)),
        ],
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
          SpellOutStringAttribute(range: const TextRange(start: 0, end: 1)),
        ],
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

    test('provides the correct isMergedIntoParent value', () {
      final root = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
      final node1 = SemanticsNode()..rect = const Rect.fromLTRB(1.0, 0.0, 10.0, 10.0);
      final node11 = SemanticsNode()..rect = const Rect.fromLTRB(2.0, 0.0, 10.0, 10.0);
      final node12 = SemanticsNode()..rect = const Rect.fromLTRB(3.0, 0.0, 10.0, 10.0);

      final noMergeConfig = SemanticsConfiguration()
        ..isSemanticBoundary = true
        ..isMergingSemanticsOfDescendants = false;

      final mergeConfig = SemanticsConfiguration()
        ..isSemanticBoundary = true
        ..isMergingSemanticsOfDescendants = true;

      node1.updateWith(
        config: noMergeConfig,
        childrenInInversePaintOrder: <SemanticsNode>[node11, node12],
      );

      expect(node1.isMergedIntoParent, false);
      expect(node1.mergeAllDescendantsIntoThisNode, false);
      expect(node11.isMergedIntoParent, false);
      expect(node12.isMergedIntoParent, false);
      expect(root.isMergedIntoParent, false);

      root.updateWith(config: mergeConfig, childrenInInversePaintOrder: <SemanticsNode>[node1]);
      expect(node1.isMergedIntoParent, true);
      expect(node1.mergeAllDescendantsIntoThisNode, false);
      expect(node11.isMergedIntoParent, true);
      expect(node12.isMergedIntoParent, true);
      expect(root.isMergedIntoParent, false);
      expect(root.mergeAllDescendantsIntoThisNode, true);

      // Change config
      node1.updateWith(
        config: mergeConfig,
        childrenInInversePaintOrder: <SemanticsNode>[node11, node12],
      );
      expect(node1.isMergedIntoParent, true);
      expect(node1.mergeAllDescendantsIntoThisNode, true);
      expect(node11.isMergedIntoParent, true);
      expect(node12.isMergedIntoParent, true);
      expect(root.isMergedIntoParent, false);
      expect(root.mergeAllDescendantsIntoThisNode, true);

      root.updateWith(config: noMergeConfig, childrenInInversePaintOrder: <SemanticsNode>[node1]);
      expect(node1.isMergedIntoParent, false);
      expect(node1.mergeAllDescendantsIntoThisNode, true);
      expect(node11.isMergedIntoParent, true);
      expect(node12.isMergedIntoParent, true);
      expect(root.isMergedIntoParent, false);
      expect(root.mergeAllDescendantsIntoThisNode, false);
    });

    test('sendSemanticsUpdate verifies no invisible nodes', () {
      const invisibleRect = Rect.fromLTRB(0.0, 0.0, 0.0, 10.0);
      const visibleRect = Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);

      final owner = SemanticsOwner(onSemanticsUpdate: (SemanticsUpdate update) {});
      final root = SemanticsNode.root(owner: owner)..rect = invisibleRect;
      final child = SemanticsNode();

      // It's ok to have an invisible root.
      expect(owner.sendSemanticsUpdate, returnsNormally);

      // It's ok to have an invisible child if it's merged to an ancestor.
      root
        ..rect = visibleRect
        ..updateWith(
          config: SemanticsConfiguration()
            ..isSemanticBoundary = true
            ..isMergingSemanticsOfDescendants = true,
          childrenInInversePaintOrder: <SemanticsNode>[child..rect = invisibleRect],
        );
      expect(owner.sendSemanticsUpdate, returnsNormally);

      // It's ok if all nodes are visible.
      root
        ..rect = visibleRect
        ..updateWith(
          config: SemanticsConfiguration()
            ..isSemanticBoundary = true
            ..isMergingSemanticsOfDescendants = false,
          childrenInInversePaintOrder: <SemanticsNode>[child..rect = visibleRect],
        );
      expect(owner.sendSemanticsUpdate, returnsNormally);

      // Invisible root with children bad.
      root
        ..rect = invisibleRect
        ..updateWith(
          config: SemanticsConfiguration()
            ..isSemanticBoundary = true
            ..isMergingSemanticsOfDescendants = true,
          childrenInInversePaintOrder: <SemanticsNode>[child..rect = invisibleRect],
        );
      expect(
        owner.sendSemanticsUpdate,
        throwsA(
          isA<FlutterError>().having(
            (FlutterError error) => error.message,
            'message',
            equals(
              'Invisible SemanticsNodes should not be added to the tree.\n'
              'The following invisible SemanticsNodes were added to the tree:\n'
              'SemanticsNode#0(dirty, merge boundary ⛔️, Rect.fromLTRB(0.0, 0.0, 0.0, 10.0), invisible)\n'
              'which was added as the root SemanticsNode\n'
              'An invisible SemanticsNode is one whose rect is not on screen hence not reachable for users, and its semantic information is not merged into a visible parent.\n'
              'An invisible SemanticsNode makes the accessibility experience confusing, as it does not provide any visual indication when the user selects it via accessibility technologies.\n'
              'Consider removing the above invisible SemanticsNodes if they were added by your RenderObject.assembleSemanticsNode implementation, or filing a bug on GitHub:\n'
              '  https://github.com/flutter/flutter/issues/new?template=02_bug.yml',
            ),
          ),
        ),
      );

      // Invisible children bad.
      root
        ..rect = visibleRect
        ..updateWith(
          config: SemanticsConfiguration()
            ..isSemanticBoundary = true
            ..isMergingSemanticsOfDescendants = false,
          childrenInInversePaintOrder: <SemanticsNode>[child..rect = invisibleRect],
        );
      expect(
        owner.sendSemanticsUpdate,
        throwsA(
          isA<FlutterError>().having(
            (FlutterError error) => error.message,
            'message',
            equals(
              'Invisible SemanticsNodes should not be added to the tree.\n'
              'The following invisible SemanticsNodes were added to the tree:\n'
              'SemanticsNode#1(dirty, Rect.fromLTRB(0.0, 0.0, 0.0, 10.0), invisible)\n'
              'which was added as a child of:\n'
              '  SemanticsNode#0(dirty, Rect.fromLTRB(0.0, 0.0, 10.0, 10.0))\n'
              'An invisible SemanticsNode is one whose rect is not on screen hence not reachable for users, and its semantic information is not merged into a visible parent.\n'
              'An invisible SemanticsNode makes the accessibility experience confusing, as it does not provide any visual indication when the user selects it via accessibility technologies.\n'
              'Consider removing the above invisible SemanticsNodes if they were added by your RenderObject.assembleSemanticsNode implementation, or filing a bug on GitHub:\n'
              '  https://github.com/flutter/flutter/issues/new?template=02_bug.yml',
            ),
          ),
        ),
      );
    });

    test('mutate existing semantic node list errors', () {
      final node = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);

      final config = SemanticsConfiguration()
        ..isSemanticBoundary = true
        ..isMergingSemanticsOfDescendants = true;

      final children = <SemanticsNode>[
        SemanticsNode()..rect = const Rect.fromLTRB(5.0, 5.0, 10.0, 10.0),
      ];

      node.updateWith(config: config, childrenInInversePaintOrder: children);

      children.add(SemanticsNode()..rect = const Rect.fromLTRB(42.0, 42.0, 52.0, 52.0));

      {
        late FlutterError error;
        try {
          node.updateWith(config: config, childrenInInversePaintOrder: children);
        } on FlutterError catch (e) {
          error = e;
        }
        expect(
          error.toString(),
          equalsIgnoringHashCodes(
            'Failed to replace child semantics nodes because the list of `SemanticsNode`s was mutated.\n'
            'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.\n'
            'Error details:\n'
            "The list's length has changed from 1 to 2.",
          ),
        );
        expect(
          error.diagnostics
              .singleWhere((DiagnosticsNode node) => node.level == DiagnosticLevel.hint)
              .toString(),
          'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.',
        );
      }

      {
        late FlutterError error;
        final modifiedChildren = <SemanticsNode>[
          SemanticsNode()..rect = const Rect.fromLTRB(5.0, 5.0, 10.0, 10.0),
          SemanticsNode()..rect = const Rect.fromLTRB(10.0, 10.0, 20.0, 20.0),
        ];
        node.updateWith(config: config, childrenInInversePaintOrder: modifiedChildren);
        try {
          modifiedChildren[0] = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 20.0, 20.0);
          modifiedChildren[1] = SemanticsNode()..rect = const Rect.fromLTRB(40.0, 14.0, 60.0, 60.0);
          node.updateWith(config: config, childrenInInversePaintOrder: modifiedChildren);
        } on FlutterError catch (e) {
          error = e;
        }
        expect(
          error.toStringDeep(),
          equalsIgnoringHashCodes(
            'FlutterError\n'
            '   Failed to replace child semantics nodes because the list of\n'
            '   `SemanticsNode`s was mutated.\n'
            '   Instead of mutating the existing list, create a new list\n'
            '   containing the desired `SemanticsNode`s.\n'
            '   Error details:\n'
            '   Child node at position 0 was replaced:\n'
            '   Previous child: SemanticsNode#4(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(5.0, 5.0, 10.0, 10.0))\n'
            '   New child: SemanticsNode#6(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(0.0, 0.0, 20.0, 20.0))\n'
            '\n'
            '   Child node at position 1 was replaced:\n'
            '   Previous child: SemanticsNode#5(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(10.0, 10.0, 20.0, 20.0))\n'
            '   New child: SemanticsNode#7(STALE, owner: null, merged up ⬆️, Rect.fromLTRB(40.0, 14.0, 60.0, 60.0))\n',
          ),
        );

        expect(
          error.diagnostics
              .singleWhere((DiagnosticsNode node) => node.level == DiagnosticLevel.hint)
              .toString(),
          'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.',
        );
        // Two previous children and two new children.
        expect(
          error.diagnostics.where((DiagnosticsNode node) => node.value is SemanticsNode).length,
          4,
        );
      }
    });

    test(
      'after markNeedsSemanticsUpdate() all render objects between two semantic boundaries are asked for annotations',
      () {
        final SemanticsHandle handle = TestRenderingFlutterBinding.instance.ensureSemantics();
        addTearDown(handle.dispose);

        TestRender middle;
        final root = TestRender(
          hasTapAction: true,
          isSemanticBoundary: true,
          child: TestRender(
            hasLongPressAction: true,
            child: middle = TestRender(
              hasScrollLeftAction: true,
              child: TestRender(
                hasScrollRightAction: true,
                child: TestRender(hasScrollUpAction: true, isSemanticBoundary: true),
              ),
            ),
          ),
        );

        layout(root);
        pumpFrame(phase: EnginePhase.flushSemantics);

        int expectedActions =
            SemanticsAction.tap.index |
            SemanticsAction.longPress.index |
            SemanticsAction.scrollLeft.index |
            SemanticsAction.scrollRight.index;
        expect(root.debugSemantics!.getSemanticsData().actions, expectedActions);

        middle
          ..hasScrollLeftAction = false
          ..hasScrollDownAction = true;
        middle.markNeedsSemanticsUpdate();

        pumpFrame(phase: EnginePhase.flushSemantics);

        expectedActions =
            SemanticsAction.tap.index |
            SemanticsAction.longPress.index |
            SemanticsAction.scrollDown.index |
            SemanticsAction.scrollRight.index;
        expect(root.debugSemantics!.getSemanticsData().actions, expectedActions);
      },
    );

    test('updateWith marks node as dirty when role changes', () {
      final node = SemanticsNode();

      expect(node.role, SemanticsRole.none);
      expect(node.debugIsDirty, isFalse);

      final config = SemanticsConfiguration()..role = SemanticsRole.tab;
      node.updateWith(config: config);

      expect(node.role, config.role);
      expect(node.debugIsDirty, isTrue);
    });
  });

  test('toStringDeep() does not throw with transform == null', () {
    final child1 = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 5.0, 5.0);
    final child2 = SemanticsNode()..rect = const Rect.fromLTRB(5.0, 0.0, 10.0, 5.0);
    final root = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 5.0);
    root.updateWith(config: null, childrenInInversePaintOrder: <SemanticsNode>[child1, child2]);

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
    const tests = <List<SemanticsSortKey>>[
      <SemanticsSortKey>[OrdinalSortKey(0.0), OrdinalSortKey(0.0)],
      <SemanticsSortKey>[OrdinalSortKey(0.0), OrdinalSortKey(1.0)],
      <SemanticsSortKey>[OrdinalSortKey(1.0), OrdinalSortKey(0.0)],
      <SemanticsSortKey>[OrdinalSortKey(1.0), OrdinalSortKey(1.0)],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'a'), OrdinalSortKey(0.0, name: 'a')],
      <SemanticsSortKey>[OrdinalSortKey(0.0, name: 'a'), OrdinalSortKey(1.0, name: 'a')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'a'), OrdinalSortKey(0.0, name: 'a')],
      <SemanticsSortKey>[OrdinalSortKey(1.0, name: 'a'), OrdinalSortKey(1.0, name: 'a')],
    ];
    final expectedResults = <int>[0, -1, 1, 0, 0, -1, 1, 0];
    assert(tests.length == expectedResults.length);
    final results = <int>[
      for (final List<SemanticsSortKey> tuple in tests) tuple[0].compareTo(tuple[1]),
    ];
    expect(results, orderedEquals(expectedResults));

    // Differing types should throw an assertion.
    expect(
      () => const OrdinalSortKey(0.0).compareTo(const CustomSortKey(0.0)),
      throwsAssertionError,
    );
  });

  test('OrdinalSortKey compares correctly when the names are different', () {
    const tests = <List<SemanticsSortKey>>[
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
    final expectedResults = <int>[-1, -1, -1, -1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1];
    assert(tests.length == expectedResults.length);
    final results = <int>[
      for (final List<SemanticsSortKey> tuple in tests) tuple[0].compareTo(tuple[1]),
    ];
    expect(results, orderedEquals(expectedResults));
  });

  test('toStringDeep respects childOrder parameter', () {
    final child1 = SemanticsNode()..rect = const Rect.fromLTRB(15.0, 0.0, 20.0, 5.0);
    final child2 = SemanticsNode()..rect = const Rect.fromLTRB(10.0, 0.0, 15.0, 5.0);
    final root = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 20.0, 5.0);
    root.updateWith(config: null, childrenInInversePaintOrder: <SemanticsNode>[child1, child2]);
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

    final child3 = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 5.0);
    child3.updateWith(
      config: null,
      childrenInInversePaintOrder: <SemanticsNode>[
        SemanticsNode()..rect = const Rect.fromLTRB(5.0, 0.0, 10.0, 5.0),
        SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 5.0, 5.0),
      ],
    );

    final rootComplex = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 25.0, 5.0);
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
    final minimalProperties = SemanticsNode();
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
      '   identifier: ""\n'
      '   traversalParentIdentifier: null\n'
      '   traversalChildIdentifier: null\n'
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
      '   indexInParent: null\n'
      '   headingLevel: 0\n',
    );

    final config = SemanticsConfiguration()
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true
      ..onScrollUp = () {}
      ..onLongPress = () {}
      ..onShowOnScreen = () {}
      ..isChecked = false
      ..isSelected = true
      ..isButton = true
      ..label = 'Use all the properties'
      ..textDirection = TextDirection.rtl
      ..sortKey = const OrdinalSortKey(1.0);
    final allProperties = SemanticsNode()
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
        '   flags: hasCheckedState, isSelected, isButton, hasSelectedState\n'
        '   label: "Use all the properties"\n'
        '   textDirection: rtl\n'
        '   sortKey: OrdinalSortKey#19df5(order: 1.0)\n',
      ),
    );
    expect(
      allProperties.getSemanticsData().toString(),
      'SemanticsData('
      'Rect.fromLTRB(50.0, 10.0, 70.0, 40.0), '
      '[1.0,0.0,0.0,10.0; 0.0,1.0,0.0,10.0; 0.0,0.0,1.0,0.0; 0.0,0.0,0.0,1.0], '
      'actions: [longPress, scrollUp, showOnScreen], '
      'flags: [hasCheckedState, isSelected, isButton, hasSelectedState], '
      'label: "Use all the properties", textDirection: rtl)',
    );

    final scaled = SemanticsNode()
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

  test('blocked actions debug properties', () {
    final config = SemanticsConfiguration()
      ..isBlockingUserActions = true
      ..onScrollUp = () {}
      ..onLongPress = () {}
      ..onShowOnScreen = () {}
      ..onDidGainAccessibilityFocus = () {};
    final blocked = SemanticsNode()
      ..rect = const Rect.fromLTWH(50.0, 10.0, 20.0, 30.0)
      ..transform = Matrix4.translation(Vector3(10.0, 10.0, 0.0))
      ..updateWith(config: config);
    expect(
      blocked.toStringDeep(),
      equalsIgnoringHashCodes(
        'SemanticsNode#1\n'
        '   STALE\n'
        '   owner: null\n'
        '   Rect.fromLTRB(60.0, 20.0, 80.0, 50.0)\n'
        '   actions: didGainAccessibilityFocus, longPress🚫️, scrollUp🚫️,\n'
        '     showOnScreen🚫️\n',
      ),
    );
  });

  test('validation result debug properties', () {
    final nodeWithValidationResult = SemanticsNode()
      ..updateWith(
        config: SemanticsConfiguration()..validationResult = SemanticsValidationResult.valid,
      );

    expect(
      nodeWithValidationResult.toStringDeep(),
      'SemanticsNode#1\n'
      '   STALE\n'
      '   owner: null\n'
      '   Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)\n'
      '   invisible\n'
      '   validationResult: valid\n',
    );
  });

  test('Custom actions debug properties', () {
    final configuration = SemanticsConfiguration();
    const action1 = CustomSemanticsAction(label: 'action1');
    const action2 = CustomSemanticsAction(label: 'action2');
    const action3 = CustomSemanticsAction(label: 'action3');
    configuration.customSemanticsActions = <CustomSemanticsAction, VoidCallback>{
      action1: () {},
      action2: () {},
      action3: () {},
    };
    final actionNode = SemanticsNode();
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
      '   identifier: ""\n'
      '   traversalParentIdentifier: null\n'
      '   traversalChildIdentifier: null\n'
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
      '   indexInParent: null\n'
      '   headingLevel: 0\n',
    );
  });

  test('Attributed String can concat', () {
    final string1 = AttributedString(
      'string1',
      attributes: <StringAttribute>[
        SpellOutStringAttribute(range: const TextRange(start: 0, end: 4)),
      ],
    );
    final string2 = AttributedString(
      'string2',
      attributes: <StringAttribute>[
        LocaleStringAttribute(
          locale: const Locale('es', 'MX'),
          range: const TextRange(start: 0, end: 4),
        ),
      ],
    );
    final AttributedString result = string1 + string2;
    expect(result.string, 'string1string2');
    expect(result.attributes.length, 2);
    expect(result.attributes[0].range, const TextRange(start: 0, end: 4));
    expect(result.attributes[0] is SpellOutStringAttribute, isTrue);
    expect(
      result.toString(),
      "AttributedString('string1string2', attributes: [SpellOutStringAttribute(TextRange(start: 0, end: 4)), LocaleStringAttribute(TextRange(start: 7, end: 11), es-MX)])",
    );
  });

  test('Semantics id does not repeat', () {
    final owner = SemanticsOwner(onSemanticsUpdate: (SemanticsUpdate update) {});
    const expectId = 1400;
    SemanticsNode? nodeToRemove;
    for (var i = 0; i < kMaxFrameworkAccessibilityIdentifier; i++) {
      final node = SemanticsNode();
      node.attach(owner);
      if (node.id == expectId) {
        nodeToRemove = node;
      }
    }
    nodeToRemove!.detach();
    final newNode = SemanticsNode();
    newNode.attach(owner);
    // Id is reused.
    expect(newNode.id, expectId);
  });

  test('performActionAt can hit test on merged semantics node', () {
    var tapped = false;
    final owner = SemanticsOwner(onSemanticsUpdate: (SemanticsUpdate update) {});
    final root = SemanticsNode.root(owner: owner)..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    final merged = SemanticsNode()..rect = const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    final mergeConfig = SemanticsConfiguration()
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true
      ..onTap = () => tapped = true;
    final rootConfig = SemanticsConfiguration()..isSemanticBoundary = true;

    merged.updateWith(config: mergeConfig, childrenInInversePaintOrder: <SemanticsNode>[]);
    root.updateWith(config: rootConfig, childrenInInversePaintOrder: <SemanticsNode>[merged]);

    owner.performActionAt(const Offset(5, 5), SemanticsAction.tap);
    expect(tapped, isTrue);
  });

  test('Tags show up in debug properties', () {
    final actionNode = SemanticsNode()..tags = <SemanticsTag>{RenderViewport.useTwoPaneSemantics};

    expect(actionNode.toStringDeep(), contains('\n   tags: RenderViewport.twoPane\n'));
  });

  test('SemanticsConfiguration getter/setter', () {
    final config = SemanticsConfiguration();
    const customAction = CustomSemanticsAction(label: 'test');

    expect(config.isSemanticBoundary, isFalse);
    expect(config.isButton, isFalse);
    expect(config.isLink, isFalse);
    expect(config.isMergingSemanticsOfDescendants, isFalse);
    expect(config.isEnabled, null);
    expect(config.isChecked, null);
    expect(config.isSelected, isFalse);
    expect(config.isBlockingSemanticsOfPreviouslyPaintedNodes, isFalse);
    expect(config.isFocused, null);
    expect(config.isTextField, isFalse);

    expect(config.onShowOnScreen, isNull);
    expect(config.onScrollDown, isNull);
    expect(config.onScrollUp, isNull);
    expect(config.onScrollLeft, isNull);
    expect(config.onScrollRight, isNull);
    expect(config.onScrollToOffset, isNull);
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

    void onShowOnScreen() {}
    void onScrollDown() {}
    void onScrollUp() {}
    void onScrollLeft() {}
    void onScrollRight() {}
    void onScrollToOffset(Offset _) {}
    void onLongPress() {}
    void onDecrease() {}
    void onIncrease() {}
    void onMoveCursorForwardByCharacter(bool _) {}
    void onMoveCursorBackwardByCharacter(bool _) {}
    void onTap() {}
    void onCustomAction() {}

    config.onShowOnScreen = onShowOnScreen;
    config.onScrollDown = onScrollDown;
    config.onScrollUp = onScrollUp;
    config.onScrollLeft = onScrollLeft;
    config.onScrollRight = onScrollRight;
    config.onScrollToOffset = onScrollToOffset;
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
    expect(config.onScrollToOffset, same(onScrollToOffset));
    expect(config.onLongPress, same(onLongPress));
    expect(config.onDecrease, same(onDecrease));
    expect(config.onIncrease, same(onIncrease));
    expect(config.onMoveCursorForwardByCharacter, same(onMoveCursorForwardByCharacter));
    expect(config.onMoveCursorBackwardByCharacter, same(onMoveCursorBackwardByCharacter));
    expect(config.onTap, same(onTap));
    expect(config.customSemanticsActions[customAction], same(onCustomAction));
  });

  test('SemanticsOwner dispatches memory events', () async {
    await expectLater(
      await memoryEvents(
        () => SemanticsOwner(onSemanticsUpdate: (SemanticsUpdate update) {}).dispose(),
        SemanticsOwner,
      ),
      areCreateAndDispose,
    );
  });

  test('SemanticsNode.indexInParent appears in string output', () async {
    final node = SemanticsNode()..indexInParent = 10;
    expect(node.toString(), contains('indexInParent: 10'));
  });

  group('SemanticsLabelBuilder', () {
    test('basic functionality with default separator', () {
      final builder = SemanticsLabelBuilder();
      expect(builder.isEmpty, isTrue);
      expect(builder.length, 0);

      builder.addPart('Hello');
      expect(builder.isEmpty, isFalse);
      expect(builder.length, 1);

      builder.addPart('world');
      expect(builder.length, 2);

      final String label = builder.build();
      expect(label, 'Hello world');
    });

    test('custom separator', () {
      final builder = SemanticsLabelBuilder(separator: ', ');
      builder
        ..addPart('One')
        ..addPart('Two')
        ..addPart('Three');

      final String label = builder.build();
      expect(label, 'One, Two, Three');
    });

    test('empty separator', () {
      final builder = SemanticsLabelBuilder(separator: '');
      builder
        ..addPart('Hello')
        ..addPart('World');

      final String label = builder.build();
      expect(label, 'HelloWorld');
    });

    test('ignores empty parts', () {
      final builder = SemanticsLabelBuilder();
      builder
        ..addPart('Hello')
        ..addPart('')
        ..addPart('world');

      final String label = builder.build();
      expect(label, 'Hello world');
      expect(builder.length, 2);
    });

    test('single part', () {
      final builder = SemanticsLabelBuilder();
      builder.addPart('Single');

      final String label = builder.build();
      expect(label, 'Single');
    });

    test('empty builder', () {
      final builder = SemanticsLabelBuilder();
      final String label = builder.build();
      expect(label, '');
    });

    test('clear functionality', () {
      final builder = SemanticsLabelBuilder();
      builder
        ..addPart('Hello')
        ..addPart('world');

      expect(builder.length, 2);

      builder.clear();
      expect(builder.isEmpty, isTrue);
      expect(builder.length, 0);

      final String label = builder.build();
      expect(label, '');
    });

    test('reusable builder', () {
      final builder = SemanticsLabelBuilder();

      // First use
      builder
        ..addPart('First')
        ..addPart('use');
      expect(builder.build(), 'First use');

      // Clear and reuse
      builder.clear();
      builder
        ..addPart('Second')
        ..addPart('use');
      expect(builder.build(), 'Second use');
    });

    test('reuse without clearing', () {
      final builder = SemanticsLabelBuilder();

      // First use
      builder
        ..addPart('First')
        ..addPart('batch');
      expect(builder.build(), 'First batch');
      expect(builder.length, 2);

      // Add more parts without clearing - should accumulate
      builder
        ..addPart('Second')
        ..addPart('batch');
      expect(builder.build(), 'First batch Second batch');
      expect(builder.length, 4);

      // Add even more parts - should continue accumulating
      builder.addPart('Final');
      expect(builder.build(), 'First batch Second batch Final');
      expect(builder.length, 5);
    });
  });

  group('SemanticsLabelBuilder text direction', () {
    test('no text direction embedding when overall direction is null', () {
      final builder = SemanticsLabelBuilder();
      builder
        ..addPart('Hello', textDirection: TextDirection.ltr)
        ..addPart('مرحبا', textDirection: TextDirection.rtl);

      final String label = builder.build();
      expect(label, 'Hello مرحبا');
    });

    test('text direction embedding with LTR overall direction', () {
      final builder = SemanticsLabelBuilder(textDirection: TextDirection.ltr);
      builder
        ..addPart('Hello', textDirection: TextDirection.ltr)
        ..addPart('مرحبا', textDirection: TextDirection.rtl)
        ..addPart('world', textDirection: TextDirection.ltr);

      final String label = builder.build();
      expect(label, 'Hello \u202Bمرحبا\u202C world');
    });

    test('text direction embedding with RTL overall direction', () {
      final builder = SemanticsLabelBuilder(textDirection: TextDirection.rtl);
      builder
        ..addPart('مرحبا', textDirection: TextDirection.rtl)
        ..addPart('Hello', textDirection: TextDirection.ltr);

      final String label = builder.build();
      expect(label, 'مرحبا \u202AHello\u202C');
    });

    test('no embedding when all parts have same direction', () {
      final builder = SemanticsLabelBuilder(textDirection: TextDirection.ltr);
      builder
        ..addPart('Hello', textDirection: TextDirection.ltr)
        ..addPart('world', textDirection: TextDirection.ltr);

      final String label = builder.build();
      expect(label, 'Hello world');
    });

    test('part direction falls back to overall direction', () {
      final builder = SemanticsLabelBuilder(textDirection: TextDirection.ltr);
      builder
        ..addPart('Hello')
        ..addPart('world');

      final String label = builder.build();
      expect(label, 'Hello world');
    });

    test('complex multilingual example', () {
      final builder = SemanticsLabelBuilder(textDirection: TextDirection.ltr, separator: ', ');
      builder
        ..addPart('Welcome', textDirection: TextDirection.ltr)
        ..addPart('مرحبا', textDirection: TextDirection.rtl) // Arabic
        ..addPart('שלום', textDirection: TextDirection.rtl) // Hebrew
        ..addPart('to our app', textDirection: TextDirection.ltr);

      expect(builder.build(), 'Welcome, \u202Bمرحبا\u202C, \u202Bשלום\u202C, to our app');
    });
  });

  group('Edge cases and error handling', () {
    test('very long labels', () {
      final builder = SemanticsLabelBuilder();
      final String longText = 'A' * 1000;

      builder
        ..addPart(longText)
        ..addPart('short');

      final String label = builder.build();
      expect(label.length, 1006); // 1000 + 1 (space) + 5
      expect(label, startsWith('AAAA'));
      expect(label, endsWith(' short'));
    });

    test('many parts', () {
      final builder = SemanticsLabelBuilder();

      for (var i = 0; i < 100; i++) {
        builder.addPart('part$i');
      }

      final String label = builder.build();
      expect(label, startsWith('part0 part1'));
      expect(label, endsWith('part98 part99'));
      expect(builder.length, 100);
    });

    test('special characters in separators', () {
      final builder = SemanticsLabelBuilder(separator: ' | ');
      builder
        ..addPart('first')
        ..addPart('second')
        ..addPart('third');

      final String label = builder.build();
      expect(label, 'first | second | third');
    });

    test('Unicode characters in content', () {
      final builder = SemanticsLabelBuilder();
      builder
        ..addPart('Emoji: 😀🎉')
        ..addPart('Math: ∑∆π')
        ..addPart('Currency: €£¥');

      final String label = builder.build();
      expect(label, 'Emoji: 😀🎉 Math: ∑∆π Currency: €£¥');
    });
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
      config.onTap = () {};
    }
    if (hasLongPressAction) {
      config.onLongPress = () {};
    }
    if (hasScrollLeftAction) {
      config.onScrollLeft = () {};
    }
    if (hasScrollRightAction) {
      config.onScrollRight = () {};
    }
    if (hasScrollUpAction) {
      config.onScrollUp = () {};
    }
    if (hasScrollDownAction) {
      config.onScrollDown = () {};
    }
  }
}

class CustomSortKey extends OrdinalSortKey {
  const CustomSortKey(super.order, {super.name});
}
