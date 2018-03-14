// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Floating Action Button control test', (WidgetTester tester) async {
    bool didPressButton = false;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new FloatingActionButton(
            onPressed: () {
              didPressButton = true;
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    expect(didPressButton, isFalse);
    await tester.tap(find.byType(Icon));
    expect(didPressButton, isTrue);
  });

  testWidgets('Floating Action Button tooltip', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            tooltip: 'Add',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Icon));
    expect(find.byTooltip('Add'), findsOneWidget);
  });

  testWidgets('Floating Action Button tooltip (no child)', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            tooltip: 'Add',
          ),
        ),
      ),
    );

    expect(find.byType(Text), findsNothing);
    await tester.longPress(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('Floating Action Button heroTag', (WidgetTester tester) async {
    BuildContext theContext;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              theContext = context;
              return const FloatingActionButton(heroTag: 1, onPressed: null);
            },
          ),
          floatingActionButton: const FloatingActionButton(heroTag: 2, onPressed: null),
        ),
      ),
    );
    Navigator.push(theContext, new PageRouteBuilder<Null>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return const Placeholder();
      },
    ));
    await tester.pump(); // this would fail if heroTag was the same on both FloatingActionButtons (see below).
  });

  testWidgets('Floating Action Button heroTag - with duplicate', (WidgetTester tester) async {
    BuildContext theContext;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              theContext = context;
              return const FloatingActionButton(onPressed: null);
            },
          ),
          floatingActionButton: const FloatingActionButton(onPressed: null),
        ),
      ),
    );
    Navigator.push(theContext, new PageRouteBuilder<Null>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return const Placeholder();
      },
    ));
    await tester.pump();
    expect(tester.takeException().toString(), contains('FloatingActionButton'));
  });

  testWidgets('Floating Action Button heroTag - with duplicate', (WidgetTester tester) async {
    BuildContext theContext;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              theContext = context;
              return const FloatingActionButton(heroTag: 'xyzzy', onPressed: null);
            },
          ),
          floatingActionButton: const FloatingActionButton(heroTag: 'xyzzy', onPressed: null),
        ),
      ),
    );
    Navigator.push(theContext, new PageRouteBuilder<Null>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return const Placeholder();
      },
    ));
    await tester.pump();
    expect(tester.takeException().toString(), contains('xyzzy'));
  });

  testWidgets('Floating Action Button semantics (enabled)', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new FloatingActionButton(
            onPressed: () { },
            child: const Icon(Icons.add, semanticLabel: 'Add'),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'Add',
          flags: <SemanticsFlag>[
            SemanticsFlag.isButton,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Floating Action Button semantics (disabled)', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const Center(
          child: const FloatingActionButton(
            onPressed: null,
            child: const Icon(Icons.add, semanticLabel: 'Add'),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'Add',
          flags: <SemanticsFlag>[
            SemanticsFlag.isButton,
            SemanticsFlag.hasEnabledState,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

    semantics.dispose();
  });

  group('ComputeNotch', () {
    testWidgets('host and guest must intersect', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester, const FloatingActionButton(onPressed: null));
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTWH(50.0, 50.0, 10.0, 10.0);
      const Offset start = const Offset(10.0, 100.0);
      const Offset end = const Offset(60.0, 100.0);
      expect(() {computeNotch(host, guest, start, end);}, throwsFlutterError);
    });

    testWidgets('start/end must be on top edge', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester, const FloatingActionButton(onPressed: null));
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);

      Offset start = const Offset(180.0, 100.0);
      Offset end = const Offset(220.0, 110.0);
      expect(() {computeNotch(host, guest, start, end);}, throwsFlutterError);

      start = const Offset(180.0, 110.0);
      end = const Offset(220.0, 100.0);
      expect(() {computeNotch(host, guest, start, end);}, throwsFlutterError);
    });

    testWidgets('start must be to the left of the notch', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester, const FloatingActionButton(onPressed: null));
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);

      const Offset start = const Offset(191.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);
      expect(() {computeNotch(host, guest, start, end);}, throwsFlutterError);
    });

    testWidgets('end must be to the right of the notch', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester, const FloatingActionButton(onPressed: null));
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);

      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(209.0, 100.0);
      expect(() {computeNotch(host, guest, start, end);}, throwsFlutterError);
    });

    testWidgets('notch no margin', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester, const FloatingActionButton(onPressed: null, notchMargin: 0.0));
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = computeNotch(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);

      expect(pathDoesNotContainCircle(notchedRectangle, guest), isTrue);
    });

    testWidgets('notch with margin', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester,
	const FloatingActionButton(onPressed: null, notchMargin: 4.0)
      );
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 90.0, 210.0, 110.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = computeNotch(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

    testWidgets('notch circle center above BAB', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester,
	const FloatingActionButton(onPressed: null, notchMargin: 4.0)
      );
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 85.0, 210.0, 105.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = computeNotch(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

    testWidgets('notch circle center below BAB', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester,
	const FloatingActionButton(onPressed: null, notchMargin: 4.0)
      );
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 95.0, 210.0, 115.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = computeNotch(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

    testWidgets('no notch when there is no overlap', (WidgetTester tester) async {
      final ComputeNotch computeNotch = await fetchComputeNotch(tester,
	const FloatingActionButton(onPressed: null, notchMargin: 4.0)
      );
      final Rect host = new Rect.fromLTRB(0.0, 100.0, 300.0, 300.0);
      final Rect guest = new Rect.fromLTRB(190.0, 40.0, 210.0, 60.0);
      const Offset start = const Offset(180.0, 100.0);
      const Offset end = const Offset(220.0, 100.0);

      final Path actualNotch = computeNotch(host, guest, start, end);
      final Path notchedRectangle =
        createNotchedRectangle(host, start.dx, end.dx, actualNotch);
      expect(pathDoesNotContainCircle(notchedRectangle, guest.inflate(4.0)), isTrue);
    });

  });

}

Path createNotchedRectangle(Rect container, double startX, double endX, Path notch) {
  return new Path()
    ..moveTo(container.left, container.top)
    ..lineTo(startX, container.top)
    ..addPath(notch, Offset.zero)
    ..lineTo(container.right, container.top)
    ..lineTo(container.right, container.bottom)
    ..lineTo(container.left, container.bottom)
    ..close();
}
Future<ComputeNotch> fetchComputeNotch(WidgetTester tester, FloatingActionButton fab) async {
      await tester.pumpWidget(new MaterialApp(
          home: new Scaffold(
            body: new ConstrainedBox(
              constraints: const BoxConstraints.expand(height: 80.0),
              child: new GeometryListener(),
            ),
            floatingActionButton: fab,
          )
      ));
      final GeometryListenerState listenerState = tester.state(find.byType(GeometryListener));
      return listenerState.cache.value.floatingActionButtonNotch;
}

class GeometryListener extends StatefulWidget {
  @override
  State createState() => new GeometryListenerState();
}

class GeometryListenerState extends State<GeometryListener> {
  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      painter: cache
    );
  }

  ValueListenable<ScaffoldGeometry> geometryListenable;
  GeometryCachePainter cache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<ScaffoldGeometry> newListenable = Scaffold.geometryOf(context);
    if (geometryListenable == newListenable)
      return;
    
    geometryListenable = newListenable;
    cache = new GeometryCachePainter(geometryListenable);
  }

}

// The Scaffold.geometryOf() value is only available at paint time.
// To fetch it for the tests we implement this CustomPainter that just
// caches the ScaffoldGeometry value in its paint method.
class GeometryCachePainter extends CustomPainter {
  GeometryCachePainter(this.geometryListenable) : super(repaint: geometryListenable);

  final ValueListenable<ScaffoldGeometry> geometryListenable;

  ScaffoldGeometry value;
  @override
  void paint(Canvas canvas, Size size) {
    value = geometryListenable.value;
  }

  @override
  bool shouldRepaint(GeometryCachePainter oldDelegate) {
    return true;
  }
}

bool pathDoesNotContainCircle(Path path, Rect circleBounds) {
  assert(circleBounds.width == circleBounds.height);
  final double radius = circleBounds.width / 2.0;

  for (double theta = 0.0; theta <= 2.0 * math.pi; theta += math.pi / 20.0) {
    for (double i = 0.0; i < 1; i += 0.01) {
      final double x = i * radius * math.cos(theta);
      final double y = i * radius * math.sin(theta);
      if (path.contains(new Offset(x,y) + circleBounds.center))
        return false;
    }
  }
  return true;
}
