// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Floating action button positioner', () {
    Widget build(FloatingActionButton fab, FloatingActionButtonLocation fabLocation, [_GeometryListener listener]) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(
            viewInsets: const EdgeInsets.only(bottom: 200.0),
          ),
          child: new Scaffold(
            appBar: new AppBar(title: const Text('FabLocation Test')),
            floatingActionButtonLocation: fabLocation,
            floatingActionButton: fab,
            body: listener,
          ),
        ),
      );
    }

    const FloatingActionButton fab1 = const FloatingActionButton(
        onPressed: null,
        child: const Text('1'),
      );

    testWidgets('still animates motion when the floating action button is null', (WidgetTester tester) async {
      await tester.pumpWidget(build(null, null));

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(build(null, FloatingActionButtonLocation.endFloat));

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(build(null, FloatingActionButtonLocation.centerFloat));

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('moves fab from center to end and back', (WidgetTester tester) async {
      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.endFloat));

      expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(756.0, 356.0));
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.centerFloat));

      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpAndSettle();

      expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(400.0, 356.0));
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.endFloat));
      
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpAndSettle();

      expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(756.0, 356.0));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('moves to and from custom-defined positions', (WidgetTester tester) async {
      await tester.pumpWidget(build(fab1, _kTopStartFabLocation));

      expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(44.0, 56.0));

      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.centerFloat));
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpAndSettle();

      expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(400.0, 356.0));
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(build(fab1, _kTopStartFabLocation));
      
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpAndSettle();

      expect(tester.getCenter(find.byType(FloatingActionButton)), const Offset(44.0, 56.0));
      expect(tester.binding.transientCallbackCount, 0);

    });

    testWidgets('interrupts in-progress animations without jumps', (WidgetTester tester) async {
      final _GeometryListener geometryListener = new _GeometryListener();
      ScaffoldGeometry geometry;
      _GeometryListenerState listenerState;
      Size previousRect;
      // The maximum amounts we expect the fab width and height to change during one step of a transition.
      const double maxDeltaWidth = 12.0;
      const double maxDeltaHeight = 12.0;
      // Measure the delta in width and height of the fab, and check that it never grows
      // by more than the expected maximum deltas.
      void check() {
        geometry = listenerState.cache.value;
        final Size currentRect = geometry.floatingActionButtonArea?.size;
        // Measure the delta in width and height of the rect, and check that it never grows
        // by more than a safe amount.
        if (previousRect != null && currentRect != null) {
          final double deltaWidth = currentRect.width - previousRect.width;
          final double deltaHeight = currentRect.height - previousRect.height;
          expect(deltaWidth.abs(), lessThanOrEqualTo(maxDeltaWidth), reason: "The Floating Action Button's width should not change faster than $maxDeltaWidth per animation step.");
          expect(deltaHeight.abs(), lessThanOrEqualTo(maxDeltaHeight), reason: "The Floating Action Button's width should not change faster than $maxDeltaHeight per animation step.");
        }
        previousRect = currentRect;
      }

      // We'll listen to the Scaffold's geometry for any 'jumps' to a size of 1 to detect changes in the size and rotation of the fab.
      // Creating a scaffold with the fab at endFloat
      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.endFloat, geometryListener));
      
      listenerState = tester.state(find.byType(_GeometryListener));
      listenerState.geometryListenable.addListener(check);
      
      // Moving the fab to centerFloat'
      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.centerFloat, geometryListener));
      await tester.pumpAndSettle();

      // Moving the fab to the top start after finishing the previous motion
      await tester.pumpWidget(build(fab1, _kTopStartFabLocation, geometryListener));

      // Interrupting motion to move to the end float
      await tester.pumpWidget(build(fab1, FloatingActionButtonLocation.endFloat, geometryListener));
      await tester.pumpAndSettle();
    });

  });
}


class _GeometryListener extends StatefulWidget {
  @override
  State createState() => new _GeometryListenerState();
}

class _GeometryListenerState extends State<_GeometryListener> {
  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      painter: cache
    );
  }

  int numNotifications = 0;
  ValueListenable<ScaffoldGeometry> geometryListenable;
  _GeometryCachePainter cache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<ScaffoldGeometry> newListenable = Scaffold.geometryOf(context);
    if (geometryListenable == newListenable)
      return;

    if (geometryListenable != null)
      geometryListenable.removeListener(onGeometryChanged);
    
    geometryListenable = newListenable;
    geometryListenable.addListener(onGeometryChanged);
    cache = new _GeometryCachePainter(geometryListenable);
  }

  void onGeometryChanged() {
    numNotifications += 1;
  }
}


// The Scaffold.geometryOf() value is only available at paint time.
// To fetch it for the tests we implement this CustomPainter that just
// caches the ScaffoldGeometry value in its paint method.
class _GeometryCachePainter extends CustomPainter {
  _GeometryCachePainter(this.geometryListenable) : super(repaint: geometryListenable);

  final ValueListenable<ScaffoldGeometry> geometryListenable;

  ScaffoldGeometry value;
  @override
  void paint(Canvas canvas, Size size) {
    value = geometryListenable.value;
  }

  @override
  bool shouldRepaint(_GeometryCachePainter oldDelegate) {
    return true;
  }
}

const _TopStartFabLocation _kTopStartFabLocation = const _TopStartFabLocation();

class _TopStartFabLocation extends FloatingActionButtonLocation {
  const _TopStartFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = 16.0 + scaffoldGeometry.minInsets.left;
    final double fabY = scaffoldGeometry.contentTop - (scaffoldGeometry.floatingActionButtonSize.height / 2.0);
    return new Offset(fabX, fabY);
  }
}