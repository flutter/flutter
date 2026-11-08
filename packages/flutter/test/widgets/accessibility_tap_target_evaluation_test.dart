// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/src/widgets/_accessibility_evaluations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final Axis axis in Axis.values) {
    for (final reverse in <bool>[false, true]) {
      testWidgets('Undersized target in non-scrolling $axis viewport, reverse: $reverse', (
        WidgetTester tester,
      ) async {
        // Regression test for https://github.com/flutter/flutter/issues/173208.
        await tester.pumpWidget(
          TestWidgetsApp(
            home: Center(
              child: SizedBox.square(
                dimension: 200.0,
                child: SingleChildScrollView(
                  scrollDirection: axis,
                  reverse: reverse,
                  child: Semantics(onTap: () {}, child: const SizedBox.square(dimension: 40.0)),
                ),
              ),
            ),
          ),
        );
        final EvaluationResult result = await const MinimumTapTargetEvaluation(
          size: Size(48.0, 48.0),
        ).evaluate(tester.binding);
        expect(result.violations, hasLength(1));
      });

      testWidgets('Undersized targets at $axis scroll limits, reverse: $reverse', (
        WidgetTester tester,
      ) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          TestWidgetsApp(
            home: Center(
              child: SizedBox.square(
                dimension: 200.0,
                child: SingleChildScrollView(
                  controller: controller,
                  scrollDirection: axis,
                  reverse: reverse,
                  child: Flex(
                    direction: axis,
                    children: <Widget>[
                      Semantics(onTap: () {}, child: const SizedBox.square(dimension: 40.0)),
                      const SizedBox.square(dimension: 520.0),
                      Semantics(onTap: () {}, child: const SizedBox.square(dimension: 40.0)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        for (final offset in <double>[0.0, 400.0]) {
          controller.jumpTo(offset);
          await tester.pump();
          final EvaluationResult result = await const MinimumTapTargetEvaluation(
            size: Size(48.0, 48.0),
          ).evaluate(tester.binding);
          expect(result.violations, hasLength(1), reason: 'offset: $offset');
        }
      });

      testWidgets('Undersized target at $axis cross-axis boundary, reverse: $reverse', (
        WidgetTester tester,
      ) async {
        final controller = ScrollController(initialScrollOffset: 200.0);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          TestWidgetsApp(
            home: Center(
              child: SizedBox.square(
                dimension: 200.0,
                child: SingleChildScrollView(
                  controller: controller,
                  scrollDirection: axis,
                  reverse: reverse,
                  child: Flex(
                    direction: axis,
                    crossAxisAlignment: .start,
                    children: <Widget>[
                      const SizedBox.square(dimension: 280.0),
                      Semantics(onTap: () {}, child: const SizedBox.square(dimension: 40.0)),
                      const SizedBox.square(dimension: 280.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final EvaluationResult result = await const MinimumTapTargetEvaluation(
          size: Size(48.0, 48.0),
        ).evaluate(tester.binding);
        expect(result.violations, hasLength(1));
      });

      testWidgets('Partially scrolled offscreen $axis targets are skipped, reverse: $reverse', (
        WidgetTester tester,
      ) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          TestWidgetsApp(
            home: Center(
              child: Transform.scale(
                scale: 1.5,
                child: SizedBox.square(
                  dimension: 200.0,
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: axis,
                    reverse: reverse,
                    child: Flex(
                      direction: axis,
                      children: <Widget>[
                        Semantics(
                          key: const ValueKey<String>('leading target'),
                          onTap: () {},
                          child: const SizedBox.square(dimension: 100.0),
                        ),
                        const SizedBox.square(dimension: 400.0),
                        Semantics(
                          key: const ValueKey<String>('trailing target'),
                          onTap: () {},
                          child: const SizedBox.square(dimension: 100.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        for (final offset in <double>[90.0, 310.0]) {
          controller.jumpTo(offset);
          await tester.pump();
          final leadingTargetIsVisible = (offset == 90.0) != reverse;
          final SemanticsNode target = tester.getSemantics(
            find.byKey(
              ValueKey<String>(leadingTargetIsVisible ? 'leading target' : 'trailing target'),
            ),
          );
          expect(target.flagsCollection.isHidden, isFalse);
          expect(axis == Axis.vertical ? target.rect.height : target.rect.width, 10.0);
          final EvaluationResult result = await const MinimumTapTargetEvaluation(
            size: Size(48.0, 48.0),
          ).evaluate(tester.binding);
          expect(result.violations, isEmpty);
        }
      });
    }
  }
}
