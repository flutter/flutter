// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math show pi;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PhysicalModel updates clipBehavior in updateRenderObject', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PhysicalModel(color: Colors.red)),
    );

    final RenderPhysicalModel renderPhysicalModel = tester.allRenderObjects.whereType<RenderPhysicalModel>().first;

    expect(renderPhysicalModel.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      const MaterialApp(home: PhysicalModel(clipBehavior: Clip.antiAlias, color: Colors.red)),
    );

    expect(renderPhysicalModel.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PhysicalShape updates clipBehavior in updateRenderObject', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PhysicalShape(color: Colors.red, clipper: ShapeBorderClipper(shape: CircleBorder()))),
    );

    final RenderPhysicalShape renderPhysicalShape = tester.allRenderObjects.whereType<RenderPhysicalShape>().first;

    expect(renderPhysicalShape.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      const MaterialApp(home: PhysicalShape(clipBehavior: Clip.antiAlias, color: Colors.red, clipper: ShapeBorderClipper(shape: CircleBorder()))),
    );

    expect(renderPhysicalShape.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PhysicalModel - creates a physical model layer when it needs compositing', (WidgetTester tester) async {
    debugDisableShadows = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PhysicalModel(
          shape: BoxShape.rectangle,
          color: Colors.grey,
          shadowColor: Colors.red,
          elevation: 1.0,
          child: Material(child: TextField(controller: TextEditingController())),
        ),
      ),
    );
    await tester.pump();

    final RenderPhysicalModel renderPhysicalModel = tester.allRenderObjects.whereType<RenderPhysicalModel>().first;
    expect(renderPhysicalModel.needsCompositing, true);

    final PhysicalModelLayer physicalModelLayer = tester.layers.whereType<PhysicalModelLayer>().first;
    expect(physicalModelLayer.shadowColor, Colors.red);
    expect(physicalModelLayer.color, Colors.grey);
    expect(physicalModelLayer.elevation, 1.0);
    debugDisableShadows = true;
  });

  testWidgets('PhysicalModel - clips when overflows and elevation is 0', (WidgetTester tester) async {
    const Key key = Key('test');
    await tester.pumpWidget(
      MediaQuery(
        key: key,
        data: const MediaQueryData(devicePixelRatio: 1.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Row(
              children: const <Widget>[
                Material(child: Text('A long long long long long long long string')),
                Material(child: Text('A long long long long long long long string')),
                Material(child: Text('A long long long long long long long string')),
                Material(child: Text('A long long long long long long long string')),
              ],
            ),
          ),
        ),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.diagnostics.first.level, DiagnosticLevel.summary);
    expect(exception.diagnostics.first.toString(), startsWith('A RenderFlex overflowed by '));
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('physical_model_overflow.png'),
    );
  });

  group('PhysicalModelLayer checks elevation', () {
    Future<void> _testStackChildren(
      WidgetTester tester,
      List<Widget> children, {
      required int expectedErrorCount,
      bool enableCheck = true,
    }) async {
      assert(expectedErrorCount != null);
      if (enableCheck) {
        debugCheckElevationsEnabled = true;
      } else {
        assert(expectedErrorCount == 0, 'Cannot expect errors if check is disabled.');
      }
      debugDisableShadows = false;
      int count = 0;
      final void Function(FlutterErrorDetails)? oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        count++;
      };
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
            children: children,
          ),
        ),
      );
      FlutterError.onError = oldOnError;
      expect(count, expectedErrorCount);
      if (enableCheck) {
        debugCheckElevationsEnabled = false;
      }
      debugDisableShadows = true;
    }

    // Tests:
    //
    //        ───────────             (red rect, paints second, child)
    //              │
    //        ───────────             (green rect, paints first)
    //            │
    // ────────────────────────────
    testWidgets('entirely overlapping, direct child', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Container(
          width: 300,
          height: 300,
          child: const Material(
            elevation: 1.0,
            color: Colors.green,
            child: Material(
              elevation: 2.0,
              color: Colors.red,
            ),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 0);
      expect(find.byType(Material), findsNWidgets(2));
    });


    // Tests:
    //
    //        ───────────────          (green rect, paints second)
    //        ─────────── │            (blue rect, paints first)
    //         │          │
    //         │          │
    // ────────────────────────────
    testWidgets('entirely overlapping, correct painting order', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Container(
          width: 300,
          height: 300,
          child: const Material(
            elevation: 1.0,
            color: Colors.green,
          ),
        ),
        Container(
          width: 300,
          height: 300,
          child: const Material(
            elevation: 2.0,
            color: Colors.blue,
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 0);
      expect(find.byType(Material), findsNWidgets(2));
    });


    // Tests:
    //
    //        ───────────────          (green rect, paints first)
    //         │  ───────────          (blue rect, paints second)
    //         │        │
    //         │        │
    // ────────────────────────────
    testWidgets('entirely overlapping, wrong painting order', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Container(
          width: 300,
          height: 300,
          child: const Material(
            elevation: 2.0,
            color: Colors.green,
          ),
        ),
        Container(
          width: 300,
          height: 300,
          child: const Material(
            elevation: 1.0,
            color: Colors.blue,
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 1);
      expect(find.byType(Material), findsNWidgets(2));
    });


    // Tests:
    //
    //  ───────────────                      (brown rect, paints first)
    //         │        ───────────          (red circle, paints second)
    //         │            │
    //         │            │
    // ────────────────────────────
    testWidgets('not non-rect not overlapping, wrong painting order', (WidgetTester tester) async {
      // These would be overlapping if we only took the rectangular bounds of the circle.
      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(150, 150, 150, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 3.0,
              color: Colors.brown,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(20, 20, 140, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 2.0,
              color: Colors.red,
              shape: CircleBorder(),
            ),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 0);
      expect(find.byType(Material), findsNWidgets(2));
    }, skip: isBrowser);  // https://github.com/flutter/flutter/issues/52855

    // Tests:
    //
    //        ───────────────          (brown rect, paints first)
    //         │  ───────────          (red circle, paints second)
    //         │        │
    //         │        │
    // ────────────────────────────
    testWidgets('not non-rect entirely overlapping, wrong painting order', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(20, 20, 140, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 3.0,
              color: Colors.brown,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(50, 50, 100, 100),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 2.0,
              color: Colors.red,
              shape: CircleBorder(),
            ),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 1);
      expect(find.byType(Material), findsNWidgets(2));
    });

    // Tests:
    //
    //   ───────────────                 (brown rect, paints first)
    //         │      ────────────       (red circle, paints second)
    //         │           │
    //         │           │
    // ────────────────────────────
    testWidgets('non-rect partially overlapping, wrong painting order', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(150, 150, 150, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 3.0,
              color: Colors.brown,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(30, 20, 150, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 2.0,
              color: Colors.red,
              shape: CircleBorder(),
            ),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 1);
      expect(find.byType(Material), findsNWidgets(2));
    });

    // Tests:
    //
    //   ───────────────                 (green rect, paints second, overlaps red rect)
    //         │
    //         │
    //   ──────────────────────────      (brown and red rects, overlapping but same elevation, paint first and third)
    //         │           │
    // ────────────────────────────
    //
    // Fails because the green rect overlaps the
    testWidgets('child partially overlapping, wrong painting order', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(150, 150, 150, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 1.0,
              color: Colors.brown,
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Material(
                  elevation: 2.0,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(30, 20, 180, 180),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 1.0,
              color: Colors.red,
            ),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 1);
      expect(find.byType(Material), findsNWidgets(3));
    });

    // Tests:
    //
    //   ───────────────                 (brown rect, paints first)
    //         │      ────────────       (red circle, paints second)
    //         │           │
    //         │           │
    // ────────────────────────────
    testWidgets('non-rect partially overlapping, wrong painting order, check disabled', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(150, 150, 150, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 3.0,
              color: Colors.brown,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(30, 20, 150, 150),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
              elevation: 2.0,
              color: Colors.red,
              shape: CircleBorder(),
            ),
          ),
        ),
      ];

      await _testStackChildren(
        tester,
        children,
        expectedErrorCount: 0,
        enableCheck: false,
      );
      expect(find.byType(Material), findsNWidgets(2));
    });

    // Tests:
    //
    //   ────────────                    (brown rect, paints first, rotated but doesn't overlap)
    //         │      ────────────       (red circle, paints second)
    //         │           │
    //         │           │
    // ────────────────────────────
    testWidgets('with a RenderTransform, non-overlapping', (WidgetTester tester) async {

      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(140, 100, 140, 150),
          child: Container(
            width: 300,
            height: 300,
            child: Transform.rotate(
              angle: math.pi / 180 * 15,
              child: const Material(
                elevation: 3.0,
                color: Colors.brown,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(50, 50, 100, 100),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
                elevation: 2.0,
                color: Colors.red,
                shape: CircleBorder()),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 0);
      expect(find.byType(Material), findsNWidgets(2));
    }, skip: isBrowser);  // https://github.com/flutter/flutter/issues/52855

    // Tests:
    //
    //   ──────────────                  (brown rect, paints first, rotated so it overlaps)
    //         │      ────────────       (red circle, paints second)
    //         │           │
    //         │           │
    // ────────────────────────────
    // This would be fine without the rotation.
    testWidgets('with a RenderTransform, overlapping', (WidgetTester tester) async {
      final List<Widget> children = <Widget>[
        Positioned.fromRect(
          rect: const Rect.fromLTWH(140, 100, 140, 150),
          child: Container(
            width: 300,
            height: 300,
            child: Transform.rotate(
              angle: math.pi / 180 * 8,
              child: const Material(
                elevation: 3.0,
                color: Colors.brown,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: const Rect.fromLTWH(50, 50, 100, 100),
          child: Container(
            width: 300,
            height: 300,
            child: const Material(
                elevation: 2.0,
                color: Colors.red,
                shape: CircleBorder()),
          ),
        ),
      ];

      await _testStackChildren(tester, children, expectedErrorCount: 1);
      expect(find.byType(Material), findsNWidgets(2));
    });
  });
}
