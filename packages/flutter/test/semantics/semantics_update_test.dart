// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
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
