// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_update_tester.dart';

void main() {
  SemanticsUpdateTestBinding();

  testWidgets('Semantics update does not send update for merged nodes.', (
    WidgetTester tester,
  ) async {
    addTearDown(SemanticsUpdateBuilderSpy.observations.clear);
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

    handle.dispose();
  });

  testWidgets('Semantics update receives attributed text', (WidgetTester tester) async {
    addTearDown(SemanticsUpdateBuilderSpy.observations.clear);
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
          child: TextButton(onPressed: () {}, child: const Text('a')),
          overlayChildBuilder: (BuildContext context) {
            return Positioned(
              left: 10,
              top: 11,
              child: OverlayPortal(
                controller: controller2,
                child: TextButton(onPressed: () {}, child: const Text('b')),
                overlayChildBuilder: (BuildContext context) {
                  // (100, 200) in 'b's coordinates.
                  return Positioned(
                    left: 110,
                    top: 211,
                    child: TextButton(onPressed: () {}, child: const Text('c')),
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
}
