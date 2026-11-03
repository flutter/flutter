// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/button_tester.dart';

typedef SemanticsNodeUpdateObservation = ({
  String label,
  List<StringAttribute>? labelAttributes,
  String value,
  List<StringAttribute>? valueAttributes,
  String hint,
  List<StringAttribute>? hintAttributes,
  Int32List childrenInTraversalOrder,
  Int32List childrenInHitTestOrder,
  Float64List transform,
});

void main() {
  SemanticsUpdateTestBinding();

  testWidgets('Semantics update does not send update for merged nodes.', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    // Pumps a placeholder to trigger the warm up frame.
    await tester.pumpWidget(
      const Placeholder(),
      // Stops right after the warm up frame.
      phase: EnginePhase.build,
    );
    // The warm up frame will send update for an empty semantics tree. We
    // ignore this one time update.
    SemanticsUpdateBuilderSpy.observations.clear();

    // Builds the real widget tree.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            label: 'outer',
            // This semantics node should not be part of the semantics update
            // because it is under another semantics container.
            child: Semantics(label: 'inner', container: true, child: const Text('text')),
          ),
        ),
      ),
    );

    expect(SemanticsUpdateBuilderSpy.observations.length, 2);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(0), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder[0], 1);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(1), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.childrenInTraversalOrder.length, 0);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.label, 'outer\ninner\ntext');

    SemanticsUpdateBuilderSpy.observations.clear();

    // Updates the inner semantics label and verifies it only sends update for
    // the merged parent.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MergeSemantics(
          child: Semantics(
            label: 'outer',
            // This semantics node should not be part of the semantics update
            // because it is under another semantics container.
            child: Semantics(label: 'inner-updated', container: true, child: const Text('text')),
          ),
        ),
      ),
    );
    expect(SemanticsUpdateBuilderSpy.observations.length, 1);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(1), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.childrenInTraversalOrder.length, 0);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.label, 'outer\ninner-updated\ntext');

    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  });

  testWidgets('Semantics update receives attributed text', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    // Pumps a placeholder to trigger the warm up frame.
    await tester.pumpWidget(
      const Placeholder(),
      // Stops right after the warm up frame.
      phase: EnginePhase.build,
    );
    // The warm up frame will send update for an empty semantics tree. We
    // ignore this one time update.
    SemanticsUpdateBuilderSpy.observations.clear();

    // Builds the real widget tree.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          attributedLabel: AttributedString(
            'label',
            attributes: <StringAttribute>[
              SpellOutStringAttribute(range: const TextRange(start: 0, end: 5)),
            ],
          ),
          attributedValue: AttributedString(
            'value',
            attributes: <StringAttribute>[
              LocaleStringAttribute(
                range: const TextRange(start: 0, end: 5),
                locale: const Locale('en', 'MX'),
              ),
            ],
          ),
          attributedHint: AttributedString(
            'hint',
            attributes: <StringAttribute>[
              SpellOutStringAttribute(range: const TextRange(start: 1, end: 2)),
            ],
          ),
          child: const Placeholder(),
        ),
      ),
    );

    expect(SemanticsUpdateBuilderSpy.observations.length, 2);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(0), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder.length, 1);
    expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder[0], 1);

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(1), isTrue);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.childrenInTraversalOrder.length, 0);
    expect(SemanticsUpdateBuilderSpy.observations[1]!.label, 'label');
    expect(SemanticsUpdateBuilderSpy.observations[1]!.labelAttributes!.length, 1);
    expect(
      SemanticsUpdateBuilderSpy.observations[1]!.labelAttributes![0] is SpellOutStringAttribute,
      isTrue,
    );
    expect(
      SemanticsUpdateBuilderSpy.observations[1]!.labelAttributes![0].range,
      const TextRange(start: 0, end: 5),
    );

    expect(SemanticsUpdateBuilderSpy.observations[1]!.value, 'value');
    expect(SemanticsUpdateBuilderSpy.observations[1]!.valueAttributes!.length, 1);
    expect(
      SemanticsUpdateBuilderSpy.observations[1]!.valueAttributes![0] is LocaleStringAttribute,
      isTrue,
    );
    final localeAttribute =
        SemanticsUpdateBuilderSpy.observations[1]!.valueAttributes![0] as LocaleStringAttribute;
    expect(localeAttribute.range, const TextRange(start: 0, end: 5));
    expect(localeAttribute.locale, const Locale('en', 'MX'));

    expect(SemanticsUpdateBuilderSpy.observations[1]!.hint, 'hint');
    expect(SemanticsUpdateBuilderSpy.observations[1]!.hintAttributes!.length, 1);
    expect(
      SemanticsUpdateBuilderSpy.observations[1]!.hintAttributes![0] is SpellOutStringAttribute,
      isTrue,
    );
    expect(
      SemanticsUpdateBuilderSpy.observations[1]!.hintAttributes![0].range,
      const TextRange(start: 1, end: 2),
    );

    expect(
      tester.widget(find.byType(Semantics)).toString(),
      'Semantics('
      'container: false, '
      'properties: SemanticsProperties, '
      'attributedLabel: "label" [SpellOutStringAttribute(TextRange(start: 0, end: 5))], '
      'attributedValue: "value" [LocaleStringAttribute(TextRange(start: 0, end: 5), en-MX)], '
      'attributedHint: "hint" [SpellOutStringAttribute(TextRange(start: 1, end: 2))]' // ignore: missing_whitespace_between_adjacent_strings
      ')',
    );

    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  });

  testWidgets('Semantics update receives correct traversal transform with nested OverlayPortals', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    // Pumps a placeholder to trigger the warm up frame.
    await tester.pumpWidget(
      const Placeholder(),
      // Stops right after the warm up frame.
      phase: EnginePhase.build,
    );
    // The warm up frame will send update for an empty semantics tree. We
    // ignore this one time update.
    SemanticsUpdateBuilderSpy.observations.clear();
    final controller1 = OverlayPortalController()..show();
    final controller2 = OverlayPortalController()..show();

    final entry = OverlayEntry(
      builder: (BuildContext context) {
        return OverlayPortal(
          controller: controller1,
          child: TestButton(onPressed: () {}, child: const Text('a')),
          overlayChildBuilder: (BuildContext context) {
            return Positioned(
              left: 10,
              top: 11,
              child: OverlayPortal(
                controller: controller2,
                child: TestButton(onPressed: () {}, child: const Text('b')),
                overlayChildBuilder: (BuildContext context) {
                  // (100, 200) in 'b's coordinates.
                  return Positioned(
                    left: 110,
                    top: 211,
                    child: TestButton(onPressed: () {}, child: const Text('c')),
                  );
                },
              ),
            );
          },
        );
      },
    );
    addTearDown(() {
      entry
        ..remove()
        ..dispose();
    });

    // Builds the real widget tree.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(initialEntries: <OverlayEntry>[entry]),
      ),
    );

    // traversal parent of 'b',
    expect(
      SemanticsUpdateBuilderSpy.observations[4]!.transform,
      Matrix4.translationValues(10.0, 11.0, 0.0).storage,
    );
    // 'b'
    expect(SemanticsUpdateBuilderSpy.observations[5]!.transform, Matrix4.identity().storage);
    // parent of 'c', inverse of node#4's transform.
    expect(
      SemanticsUpdateBuilderSpy.observations[6]!.transform,
      Matrix4.translationValues(-10.0, -11.0, 0.0).storage,
    );
    // 'c'
    expect(
      SemanticsUpdateBuilderSpy.observations[7]!.transform,
      Matrix4.translationValues(110.0, 211.0, 0.0).storage,
    );
    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  }, skip: kIsWeb); // intended: the web engine handles the transform calculation itself.

  testWidgets(
    'Semantics update does not leak nodes to hit-test order when traversal parent is missing',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // Pumps a placeholder to trigger the warm up frame.
      await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
      SemanticsUpdateBuilderSpy.observations.clear();

      const identifier = '111';
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: <Widget>[
              Semantics(
                traversalChildIdentifier: identifier,
                child: const SizedBox.square(dimension: 10),
              ),
              const SizedBox.square(dimension: 10),
            ],
          ),
        ),
      );

      // SemanticsNode#0 (root) should have 0 children in both traversal order and hit-test order,
      // and the orphan traversal child should not be sent in the update.
      expect(SemanticsUpdateBuilderSpy.observations.keys, equals(<int>[0]));
      final SemanticsNodeUpdateObservation? rootObservation =
          SemanticsUpdateBuilderSpy.observations[0];
      expect(rootObservation, isNotNull);
      expect(rootObservation!.childrenInTraversalOrder, isEmpty);
      expect(rootObservation.childrenInHitTestOrder, isEmpty);

      SemanticsUpdateBuilderSpy.observations.clear();
      handle.dispose();
    },
    skip: kIsWeb, // [intended] the web engine handles the tree grafting itself.
  );

  testWidgets(
    'Semantics update skips OverlayPortal traversal child while anchor is hidden by Opacity and sends it when anchor becomes visible',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
      SemanticsUpdateBuilderSpy.observations.clear();

      final controller = OverlayPortalController()..show();
      final opacity = ValueNotifier<double>(0.0);
      addTearDown(opacity.dispose);

      final entry = OverlayEntry(
        builder: (BuildContext context) {
          return ValueListenableBuilder<double>(
            valueListenable: opacity,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: OverlayPortal(
                  controller: controller,
                  overlayChildBuilder: (BuildContext context) {
                    return TestButton(onPressed: () {}, child: const Text('portal child'));
                  },
                  child: TestButton(onPressed: () {}, child: const Text('anchor')),
                ),
              );
            },
          );
        },
      );
      addTearDown(() {
        entry
          ..remove()
          ..dispose();
      });

      // Frame 1: opacity is 0.0, so the anchor (traversal parent) is excluded from semantics,
      // while the OverlayPortal's deferred layout box (traversal child) is mounted on the Overlay.
      // No orphan nodes should be sent in the semantics update.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(initialEntries: <OverlayEntry>[entry]),
        ),
      );

      expect(SemanticsUpdateBuilderSpy.observations.keys, equals(<int>[0]));
      expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder, isEmpty);
      expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInHitTestOrder, isEmpty);

      // Frame 2: opacity becomes 1.0, so the anchor (traversal parent) enters the semantics tree.
      // The root node, anchor, traversal child, and portal child button should all be updated
      // and connected without any orphan nodes.
      SemanticsUpdateBuilderSpy.observations.clear();
      opacity.value = 1.0;
      await tester.pump();

      final allChildIdsInTraversalOrder = <int>{
        for (final SemanticsNodeUpdateObservation obs
            in SemanticsUpdateBuilderSpy.observations.values)
          ...obs.childrenInTraversalOrder,
      };
      final allChildIdsInHitTestOrder = <int>{
        for (final SemanticsNodeUpdateObservation obs
            in SemanticsUpdateBuilderSpy.observations.values)
          ...obs.childrenInHitTestOrder,
      };
      for (final int id in SemanticsUpdateBuilderSpy.observations.keys) {
        if (id != 0) {
          expect(
            allChildIdsInTraversalOrder,
            contains(id),
            reason: 'Node $id should be reachable in traversal order',
          );
          expect(
            allChildIdsInHitTestOrder,
            contains(id),
            reason: 'Node $id should be reachable in hit-test order',
          );
        }
      }
      expect(
        SemanticsUpdateBuilderSpy.observations.values.any(
          (SemanticsNodeUpdateObservation obs) => obs.label == 'anchor',
        ),
        isTrue,
      );
      expect(
        SemanticsUpdateBuilderSpy.observations.values.any(
          (SemanticsNodeUpdateObservation obs) => obs.label == 'portal child',
        ),
        isTrue,
      );

      // Frame 3: opacity becomes 0.0 again, detaching the traversal parent while the
      // OverlayPortal's deferred layout box remains attached to the Overlay.
      // The root node should update its hit-test and traversal children to be empty.
      SemanticsUpdateBuilderSpy.observations.clear();
      opacity.value = 0.0;
      await tester.pump();

      expect(SemanticsUpdateBuilderSpy.observations.keys, equals(<int>[0]));
      expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInTraversalOrder, isEmpty);
      expect(SemanticsUpdateBuilderSpy.observations[0]!.childrenInHitTestOrder, isEmpty);

      SemanticsUpdateBuilderSpy.observations.clear();
      handle.dispose();
    },
    skip: kIsWeb, // [intended] the web engine handles the tree grafting itself.
  );

  testWidgets('Semantics update removes detached OverlayPortal traversal child', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
    SemanticsUpdateBuilderSpy.observations.clear();

    final controller = OverlayPortalController()..show();
    final entry = OverlayEntry(
      builder: (BuildContext context) {
        return OverlayPortal(
          controller: controller,
          child: TestButton(onPressed: () {}, child: const Text('anchor')),
          overlayChildBuilder: (BuildContext context) {
            return TestButton(onPressed: () {}, child: const Text('menu item'));
          },
        );
      },
    );
    addTearDown(() {
      entry
        ..remove()
        ..dispose();
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(initialEntries: <OverlayEntry>[entry]),
      ),
    );

    final int anchorId = SemanticsUpdateBuilderSpy.observations.entries.singleWhere((
      MapEntry<int, SemanticsNodeUpdateObservation> entry,
    ) {
      return entry.value.label == 'anchor';
    }).key;
    final int menuItemId = SemanticsUpdateBuilderSpy.observations.entries.singleWhere((
      MapEntry<int, SemanticsNodeUpdateObservation> entry,
    ) {
      return entry.value.label == 'menu item';
    }).key;
    expect(
      SemanticsUpdateBuilderSpy.observations.values.any((
        SemanticsNodeUpdateObservation observation,
      ) {
        return observation.childrenInTraversalOrder.contains(menuItemId);
      }),
      isTrue,
    );

    SemanticsUpdateBuilderSpy.observations.clear();
    controller.hide();
    await tester.pump();

    expect(SemanticsUpdateBuilderSpy.observations.containsKey(menuItemId), isFalse);
    expect(
      SemanticsUpdateBuilderSpy.observations.values.any((
        SemanticsNodeUpdateObservation observation,
      ) {
        return listEquals(observation.childrenInTraversalOrder, <int>[anchorId]);
      }),
      isTrue,
    );
    expect(
      SemanticsUpdateBuilderSpy.observations.values.any((
        SemanticsNodeUpdateObservation observation,
      ) {
        return observation.childrenInTraversalOrder.contains(menuItemId);
      }),
      isFalse,
    );
    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  }, skip: kIsWeb); // intended: the web engine handles the traversal order itself.

  // Regression test for https://github.com/flutter/flutter/issues/190357.
  testWidgets(
    'Semantics update does not serialize orphan nodes when pushing and popping a route with OverlayPortal',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
      SemanticsUpdateBuilderSpy.observations.clear();

      final activeTree = <int, SemanticsNodeUpdateObservation>{};

      void verifyAndCommitUpdate() {
        if (SemanticsUpdateBuilderSpy.observations.isEmpty) {
          return;
        }
        activeTree.addAll(SemanticsUpdateBuilderSpy.observations);

        final reachableInTraversal = <int>{};
        void walkTraversal(int id) {
          expect(
            activeTree.containsKey(id),
            isTrue,
            reason: 'Node $id referenced in childrenInTraversalOrder was never sent in an update',
          );
          if (!reachableInTraversal.add(id)) {
            return;
          }
          activeTree[id]!.childrenInTraversalOrder.forEach(walkTraversal);
        }

        final reachableInHitTest = <int>{};
        void walkHitTest(int id) {
          expect(
            activeTree.containsKey(id),
            isTrue,
            reason: 'Node $id referenced in childrenInHitTestOrder was never sent in an update',
          );
          if (!reachableInHitTest.add(id)) {
            return;
          }
          activeTree[id]!.childrenInHitTestOrder.forEach(walkHitTest);
        }

        walkTraversal(0);
        walkHitTest(0);

        for (final int updatedId in SemanticsUpdateBuilderSpy.observations.keys) {
          expect(
            reachableInTraversal,
            contains(updatedId),
            reason: 'Updated node $updatedId is an orphan in traversal order',
          );
          expect(
            reachableInHitTest,
            contains(updatedId),
            reason: 'Updated node $updatedId is an orphan in hit-test order',
          );
        }
        expect(reachableInTraversal, equals(reachableInHitTest));

        activeTree.removeWhere((int id, _) => !reachableInTraversal.contains(id));
        SemanticsUpdateBuilderSpy.observations.clear();
      }

      final navigatorKey = GlobalKey<NavigatorState>();
      final portalController = OverlayPortalController()..show();

      await tester.pumpWidget(
        WidgetsApp(
          navigatorKey: navigatorKey,
          color: const Color(0xFF000000),
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) {
                    return TestButton(onPressed: () {}, child: const Text('home'));
                  },
            );
          },
        ),
      );
      verifyAndCommitUpdate();

      // Push a route whose transition starts at opacity 0.0 (like MaterialPageRoute / showDialog)
      // and contains an active OverlayPortal (like Material Slider).
      navigatorKey.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return FadeTransition(
                  opacity: animation,
                  child: OverlayPortal(
                    controller: portalController,
                    overlayChildBuilder: (BuildContext context) => const SizedBox.shrink(),
                    child: TestButton(onPressed: () {}, child: const Text('pushed slider')),
                  ),
                );
              },
        ),
      );

      // Step through every frame of the push transition.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        verifyAndCommitUpdate();
      }
      expect(
        activeTree.values.any((SemanticsNodeUpdateObservation obs) => obs.label == 'pushed slider'),
        isTrue,
      );

      // Pop the route and step through every frame of the reverse transition.
      navigatorKey.currentState!.pop();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        verifyAndCommitUpdate();
      }

      handle.dispose();
    },
    skip: kIsWeb, // [intended] the web engine handles the traversal order itself.
  );

  // Regression test for https://github.com/flutter/flutter/issues/193235.
  testWidgets(
    'Semantics update sends previously merged descendants when an ancestor stops merging',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
      SemanticsUpdateBuilderSpy.observations.clear();
      final engine = _EmbedderSemanticsTree();

      // Two levels of nodes under the toggled node, so that un-merging has to
      // reach past the immediate child.
      const Widget subtree = Semantics.fromProperties(
        container: true,
        properties: SemanticsProperties(label: 'inner'),
        child: Semantics.fromProperties(
          container: true,
          properties: SemanticsProperties(label: 'leaf'),
          child: SizedBox(width: 100, height: 40),
        ),
      );
      Widget build({required bool isMerging}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: _ToggleableMergeSemantics(isMerging: isMerging, child: subtree),
        );
      }

      await tester.pumpWidget(build(isMerging: true));
      engine.apply(SemanticsUpdateBuilderSpy.observations);
      // Merged nodes are not sent: only the root (#0) and the merging node.
      expect(SemanticsUpdateBuilderSpy.observations, hasLength(2));
      final int outerId = SemanticsUpdateBuilderSpy.observations.keys.singleWhere(
        (int id) => id != 0,
      );
      expect(SemanticsUpdateBuilderSpy.observations[outerId]!.childrenInTraversalOrder, isEmpty);
      expect(SemanticsUpdateBuilderSpy.observations[outerId]!.label, contains('leaf'));
      SemanticsUpdateBuilderSpy.observations.clear();

      // Stop merging without touching the subtree. `inner` and `leaf` now have
      // to be sent as standalone nodes in the same update that first lists
      // them as children.
      await tester.pumpWidget(build(isMerging: false));
      expect(tester.takeException(), isNull);
      engine.apply(SemanticsUpdateBuilderSpy.observations);
      final int innerId =
          SemanticsUpdateBuilderSpy.observations[outerId]!.childrenInTraversalOrder.single;
      final int leafId =
          SemanticsUpdateBuilderSpy.observations[innerId]!.childrenInTraversalOrder.single;
      expect(SemanticsUpdateBuilderSpy.observations[outerId]!.label, 'outer');
      expect(SemanticsUpdateBuilderSpy.observations[innerId]!.label, 'inner');
      expect(SemanticsUpdateBuilderSpy.observations[leafId]!.label, 'leaf');
      SemanticsUpdateBuilderSpy.observations.clear();

      // Start merging again: the subtree collapses back into the merging node
      // and the standalone nodes are not sent anymore.
      await tester.pumpWidget(build(isMerging: true));
      expect(tester.takeException(), isNull);
      engine.apply(SemanticsUpdateBuilderSpy.observations);
      expect(SemanticsUpdateBuilderSpy.observations[outerId]!.childrenInTraversalOrder, isEmpty);
      expect(SemanticsUpdateBuilderSpy.observations[outerId]!.label, contains('leaf'));
      expect(SemanticsUpdateBuilderSpy.observations, isNot(contains(innerId)));
      expect(SemanticsUpdateBuilderSpy.observations, isNot(contains(leafId)));
      SemanticsUpdateBuilderSpy.observations.clear();

      // The embedder forgot `inner` and `leaf` when they became unreachable, so
      // un-merging again has to send them again.
      await tester.pumpWidget(build(isMerging: false));
      expect(tester.takeException(), isNull);
      engine.apply(SemanticsUpdateBuilderSpy.observations);
      expect(SemanticsUpdateBuilderSpy.observations, containsPair(innerId, anything));
      expect(SemanticsUpdateBuilderSpy.observations, containsPair(leafId, anything));

      SemanticsUpdateBuilderSpy.observations.clear();
      handle.dispose();
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/193235.
  //
  // RenderParagraph creates the SemanticsNodes for its inline spans itself in
  // assembleSemanticsNode and caches them across builds, so unlike nodes
  // produced by render objects they are never rebuilt when an ancestor's merge
  // state changes. Their isMergedIntoParent has to be refreshed from the parent
  // node.
  testWidgets('Semantics update sends cached inline span nodes when an ancestor stops merging', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
    SemanticsUpdateBuilderSpy.observations.clear();
    final engine = _EmbedderSemanticsTree();
    final recognizer = TapGestureRecognizer()..onTap = () {};
    addTearDown(recognizer.dispose);

    Widget build({required bool isMerging}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: _ToggleableMergeSemantics(
          isMerging: isMerging,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14),
              children: <InlineSpan>[
                const TextSpan(text: 'Read the '),
                TextSpan(text: 'docs', recognizer: recognizer),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(isMerging: true));
    engine.apply(SemanticsUpdateBuilderSpy.observations);
    expect(SemanticsUpdateBuilderSpy.observations, hasLength(2));
    final int outerId = SemanticsUpdateBuilderSpy.observations.keys.singleWhere(
      (int id) => id != 0,
    );
    expect(SemanticsUpdateBuilderSpy.observations[outerId]!.childrenInTraversalOrder, isEmpty);
    SemanticsUpdateBuilderSpy.observations.clear();

    await tester.pumpWidget(build(isMerging: false));
    expect(tester.takeException(), isNull);
    // Every child id the paragraph lists must be part of this update.
    engine.apply(SemanticsUpdateBuilderSpy.observations);
    final int paragraphId =
        SemanticsUpdateBuilderSpy.observations[outerId]!.childrenInTraversalOrder.single;
    final Int32List spanIds =
        SemanticsUpdateBuilderSpy.observations[paragraphId]!.childrenInTraversalOrder;
    expect(spanIds, hasLength(2));
    expect(spanIds.map((int id) => SemanticsUpdateBuilderSpy.observations[id]!.label), <String>[
      'Read the ',
      'docs',
    ]);
    // The cached span nodes themselves have to know they are no longer
    // merged; nothing but their parent node ever updates that flag for them.
    final SemanticsNode paragraphNode = tester.renderObject(find.byType(RichText)).debugSemantics!;
    expect(paragraphNode.id, paragraphId);
    expect(paragraphNode.isMergedIntoParent, isFalse);
    paragraphNode.visitChildren((SemanticsNode span) {
      expect(span.isMergedIntoParent, isFalse, reason: 'span #${span.id}');
      return true;
    });
    SemanticsUpdateBuilderSpy.observations.clear();

    // Merge again: the cached span nodes have to become merged too, so they
    // are folded into the merging node instead of being sent on their own.
    await tester.pumpWidget(build(isMerging: true));
    expect(tester.takeException(), isNull);
    engine.apply(SemanticsUpdateBuilderSpy.observations);
    expect(SemanticsUpdateBuilderSpy.observations[outerId]!.childrenInTraversalOrder, isEmpty);
    expect(SemanticsUpdateBuilderSpy.observations[outerId]!.label, contains('docs'));
    expect(SemanticsUpdateBuilderSpy.observations.keys, isNot(contains(paragraphId)));
    for (final spanId in spanIds) {
      expect(SemanticsUpdateBuilderSpy.observations.keys, isNot(contains(spanId)));
    }
    expect(paragraphNode.isMergedIntoParent, isTrue);
    paragraphNode.visitChildren((SemanticsNode span) {
      expect(span.isMergedIntoParent, isTrue, reason: 'span #${span.id}');
      return true;
    });

    SemanticsUpdateBuilderSpy.observations.clear();
    handle.dispose();
  });

  testWidgets(
    'Semantics node that moves into a merging sibling stays merged when its old ancestor stops merging',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final GlobalKey movedKey = GlobalKey();
      final Widget moved = Semantics(
        key: movedKey,
        container: true,
        label: 'moved',
        child: const SizedBox(width: 100, height: 20),
      );

      // While `moved` lives under `inner`, the outer node merges everything.
      // In the frame where it moves under `MergeSemantics`, the outer node
      // stops merging, so `inner` is un-merged while its stale child list
      // still refers to `moved`, which by then belongs to `MergeSemantics`.
      //
      // The extra render objects around `MergeSemantics` make it deeper than
      // `inner`, so its semantics are rebuilt first and it adopts `moved`
      // before `inner` is updated.
      Widget build({required bool hasMoved}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: _ToggleableMergeSemantics(
            isMerging: !hasMoved,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: MergeSemantics(
                      child: Column(
                        children: <Widget>[
                          Semantics(
                            container: true,
                            label: 'static',
                            child: const SizedBox(width: 100, height: 20),
                          ),
                          if (hasMoved) moved,
                        ],
                      ),
                    ),
                  ),
                ),
                Semantics(
                  container: true,
                  label: 'inner',
                  child: Column(
                    children: <Widget>[
                      if (!hasMoved) moved,
                      const SizedBox(width: 100, height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(const Placeholder(), phase: EnginePhase.build);
      SemanticsUpdateBuilderSpy.observations.clear();
      await tester.pumpWidget(build(hasMoved: false));
      SemanticsUpdateBuilderSpy.observations.clear();
      await tester.pumpWidget(build(hasMoved: true));
      expect(tester.takeException(), isNull);

      // `moved` is merged into the MergeSemantics node, not sent on its own.
      // (getSemantics would skip past merged nodes, so read the node directly.)
      final SemanticsNode movedNode = tester.renderObject(find.byKey(movedKey)).debugSemantics!;
      expect(movedNode.isMergedIntoParent, isTrue);
      expect(movedNode.parent!.mergeAllDescendantsIntoThisNode, isTrue);
      expect(
        SemanticsUpdateBuilderSpy.observations.values.map(
          (SemanticsNodeUpdateObservation observation) => observation.label,
        ),
        isNot(contains('moved')),
      );
      expect(
        SemanticsUpdateBuilderSpy.observations.values.any(
          (SemanticsNodeUpdateObservation observation) =>
              observation.label.contains('static') && observation.label.contains('moved'),
        ),
        isTrue,
      );

      SemanticsUpdateBuilderSpy.observations.clear();
      handle.dispose();
    },
  );
}

/// Mirrors how an embedder maintains its copy of the semantics tree from the
/// incremental updates it receives: a node has to be sent before, or in the
/// same update as, any parent that references it, every updated node has to be
/// reachable from the root, and nodes that become unreachable are discarded.
class _EmbedderSemanticsTree {
  final Map<int, SemanticsNodeUpdateObservation> _nodes = <int, SemanticsNodeUpdateObservation>{};

  void apply(Map<int, SemanticsNodeUpdateObservation> update) {
    _nodes.addAll(update);
    for (final MapEntry<int, SemanticsNodeUpdateObservation> entry in update.entries) {
      for (final childId in <int>{
        ...entry.value.childrenInTraversalOrder,
        ...entry.value.childrenInHitTestOrder,
      }) {
        expect(
          _nodes,
          contains(childId),
          reason:
              'Node #${entry.key} lists child #$childId, which the embedder '
              'has never received.',
        );
      }
    }
    final reachable = <int>{};
    void visit(int id) {
      if (!reachable.add(id)) {
        return;
      }
      _nodes[id]!.childrenInTraversalOrder.forEach(visit);
    }

    visit(0);
    for (final int updatedId in update.keys) {
      expect(reachable, contains(updatedId), reason: 'Updated node #$updatedId is an orphan.');
    }
    _nodes.removeWhere((int id, SemanticsNodeUpdateObservation _) => !reachable.contains(id));
  }
}

/// A test widget that allows toggling the merging of its descendants' semantics
/// without replacing the underlying render object.
class _ToggleableMergeSemantics extends SingleChildRenderObjectWidget {
  const _ToggleableMergeSemantics({required this.isMerging, super.child});

  final bool isMerging;

  @override
  _RenderToggleableMergeSemantics createRenderObject(BuildContext context) {
    return _RenderToggleableMergeSemantics(isMerging);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderToggleableMergeSemantics renderObject) {
    renderObject.isMerging = isMerging;
  }
}

/// Like [MergeSemantics], but merging can be switched off and on again without
/// replacing the render object (and therefore without replacing its
/// [SemanticsNode]).
class _RenderToggleableMergeSemantics extends RenderProxyBox {
  _RenderToggleableMergeSemantics(this._isMerging);

  bool get isMerging => _isMerging;
  bool _isMerging;
  set isMerging(bool value) {
    if (_isMerging == value) {
      return;
    }
    _isMerging = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = _isMerging
      ..label = 'outer'
      ..textDirection = TextDirection.ltr;
  }
}

class SemanticsUpdateTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() {
    return SemanticsUpdateBuilderSpy();
  }
}

class SemanticsUpdateBuilderSpy extends Fake implements ui.SemanticsUpdateBuilder {
  final SemanticsUpdateBuilder _builder = ui.SemanticsUpdateBuilder();

  static Map<int, SemanticsNodeUpdateObservation> observations =
      <int, SemanticsNodeUpdateObservation>{};

  @override
  void updateNode({
    required int id,
    required SemanticsFlags flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required int? traversalParent,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required Rect rect,
    required String identifier,
    required String label,
    List<StringAttribute>? labelAttributes,
    required String value,
    List<StringAttribute>? valueAttributes,
    required String increasedValue,
    List<StringAttribute>? increasedValueAttributes,
    required String decreasedValue,
    List<StringAttribute>? decreasedValueAttributes,
    required String hint,
    List<StringAttribute>? hintAttributes,
    String? tooltip,
    TextDirection? textDirection,
    required Float64List transform,
    required Float64List hitTestTransform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
    int headingLevel = 0,
    String? linkUrl,
    SemanticsRole role = SemanticsRole.none,
    required List<String>? controlsNodes,
    SemanticsValidationResult validationResult = SemanticsValidationResult.none,
    ui.SemanticsHitTestBehavior hitTestBehavior = ui.SemanticsHitTestBehavior.defer,
    required ui.SemanticsInputType inputType,
    required ui.Locale? locale,
    required String minValue,
    required String maxValue,
  }) {
    // Makes sure we don't send the same id twice.
    assert(!observations.containsKey(id));
    observations[id] = (
      label: label,
      labelAttributes: labelAttributes,
      hint: hint,
      hintAttributes: hintAttributes,
      value: value,
      valueAttributes: valueAttributes,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      transform: transform,
    );
  }

  @override
  void updateCustomAction({required int id, String? label, String? hint, int overrideId = -1}) =>
      _builder.updateCustomAction(id: id, label: label, hint: hint, overrideId: overrideId);

  @override
  ui.SemanticsUpdate build() => _builder.build();
}
