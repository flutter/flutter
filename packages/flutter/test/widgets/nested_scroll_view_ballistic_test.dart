// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart' show Drag, DragEndDetails, DragStartDetails, Velocity;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestWidget(GlobalKey<NestedScrollViewState> key) {
  return MaterialApp(
    home: Scaffold(
      body: NestedScrollView(
        key: key,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[const SliverAppBar(pinned: true, expandedHeight: 200.0)];
        },
        body: ListView.builder(
          itemExtent: 50.0,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) => Text('Item $index'),
        ),
      ),
    ),
  );
}

void main() {
  for (final velocity in <double>[1000.0, -1000.0]) {
    testWidgets('NestedScrollView inherits the platform ballistic simulation ($velocity)', (
      WidgetTester tester,
    ) async {
      // Regression test for https://github.com/flutter/flutter/issues/73864.
      final key = GlobalKey<NestedScrollViewState>();
      await tester.pumpWidget(_buildTestWidget(key));

      final ScrollPosition outer = key.currentState!.outerController.position;
      final ScrollPosition inner = key.currentState!.innerController.position;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 1000.0,
        pixels: 500.0,
        viewportDimension: outer.viewportDimension,
        axisDirection: outer.axisDirection,
        devicePixelRatio: outer.devicePixelRatio,
      );
      final Simulation outerSimulation = outer.physics.createBallisticSimulation(
        metrics,
        velocity,
      )!;
      final Simulation innerSimulation = inner.physics.createBallisticSimulation(
        metrics,
        velocity,
      )!;

      for (final time in <double>[0.016, 0.1, 0.2]) {
        expect(outerSimulation.x(time), moreOrLessEquals(innerSimulation.x(time), epsilon: 0.01));
        expect(outerSimulation.dx(time), moreOrLessEquals(innerSimulation.dx(time), epsilon: 0.01));
      }
    }, variant: TargetPlatformVariant.all());

    testWidgets('NestedScrollView crosses the header boundary in order ($velocity)', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey<NestedScrollViewState>();
      await tester.pumpWidget(_buildTestWidget(key));

      final ScrollPosition outer = key.currentState!.outerController.position;
      final ScrollPosition inner = key.currentState!.innerController.position;
      if (velocity < 0.0) {
        key.currentState!.outerController.jumpTo(outer.maxScrollExtent);
        key.currentState!.innerController.jumpTo(100.0);
      } else {
        // Start close enough to the boundary to cross it on every platform.
        key.currentState!.outerController.jumpTo(outer.maxScrollExtent - 100.0);
      }
      await tester.pumpAndSettle();

      final Drag drag = inner.drag(DragStartDetails(), () {});
      drag.end(
        DragEndDetails(
          primaryVelocity: -velocity,
          velocity: Velocity(pixelsPerSecond: Offset(0.0, -velocity)),
        ),
      );
      await tester.pump();
      double previousPixels = outer.pixels + inner.pixels;
      for (var frame = 0; frame < 16; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        final double pixels = outer.pixels + inner.pixels;
        expect(pixels, velocity > 0.0 ? greaterThan(previousPixels) : lessThan(previousPixels));
        previousPixels = pixels;
        expect(outer.pixels, inInclusiveRange(outer.minScrollExtent, outer.maxScrollExtent));
        if (inner.pixels > inner.minScrollExtent) {
          expect(outer.pixels, outer.maxScrollExtent);
        }
      }
      if (velocity > 0.0) {
        expect(outer.pixels, outer.maxScrollExtent);
        expect(inner.pixels, greaterThan(inner.minScrollExtent));
      } else {
        expect(inner.pixels, inner.minScrollExtent);
        expect(outer.pixels, lessThan(outer.maxScrollExtent));
      }
      await tester.pumpAndSettle();
    }, variant: TargetPlatformVariant.all());

    testWidgets(
      'NestedScrollView follows one ballistic trajectory across the header boundary on iOS '
      '($velocity)',
      (WidgetTester tester) async {
        final key = GlobalKey<NestedScrollViewState>();
        await tester.pumpWidget(_buildTestWidget(key));

        final ScrollPosition outer = key.currentState!.outerController.position;
        final ScrollPosition inner = key.currentState!.innerController.position;
        if (velocity < 0.0) {
          key.currentState!.outerController.jumpTo(outer.maxScrollExtent);
          key.currentState!.innerController.jumpTo(100.0);
        } else {
          key.currentState!.outerController.jumpTo(outer.maxScrollExtent - 100.0);
        }
        await tester.pumpAndSettle();
        final Simulation simulation = inner.physics.createBallisticSimulation(
          FixedScrollMetrics(
            minScrollExtent: outer.minScrollExtent,
            maxScrollExtent: outer.maxScrollExtent + inner.maxScrollExtent,
            pixels: outer.pixels + inner.pixels,
            viewportDimension: outer.viewportDimension,
            axisDirection: outer.axisDirection,
            devicePixelRatio: outer.devicePixelRatio,
          ),
          velocity,
        )!;

        final Drag drag = inner.drag(DragStartDetails(), () {});
        drag.end(
          DragEndDetails(
            primaryVelocity: -velocity,
            velocity: Velocity(pixelsPerSecond: Offset(0.0, -velocity)),
          ),
        );
        await tester.pump();
        for (var frame = 1; frame <= 16; frame += 1) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            outer.pixels + inner.pixels,
            moreOrLessEquals(simulation.x(frame * 0.016), epsilon: 0.01),
            reason: 'The header and body should follow one trajectory at frame $frame.',
          );
        }
        if (velocity > 0.0) {
          expect(outer.pixels, outer.maxScrollExtent);
          expect(inner.pixels, greaterThan(inner.minScrollExtent));
        } else {
          expect(inner.pixels, inner.minScrollExtent);
          expect(outer.pixels, lessThan(outer.maxScrollExtent));
        }
        await tester.pumpAndSettle();
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
    );
  }
}
