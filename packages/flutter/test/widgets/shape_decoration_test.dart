// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['reduced-test-set'])
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../painting/mocks_for_image_cache.dart';
import '../rendering/mock_canvas.dart';
import 'test_border.dart' show TestBorder;

Future<void> main() async {
  AutomatedTestWidgetsFlutterBinding();
  final ui.Image rawImage = await decodeImageFromList(Uint8List.fromList(kTransparentImage));
  final ImageProvider image = TestImageProvider(0, 0, image: rawImage);
  testWidgets('ShapeDecoration.image', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: ShapeDecoration(
            shape: Border.all(color: Colors.white) +
                   Border.all(),
            image: DecorationImage(
              image: image,
            ),
          ),
        ),
      ),
    );
    expect(
      find.byType(DecoratedBox),
      paints
        ..drawImageRect(image: rawImage)
        ..rect(color: Colors.black)
        ..rect(color: Colors.white),
    );
  });

  testWidgets('ShapeDecoration.color', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: ShapeDecoration(
            shape: Border.all(color: Colors.white) +
                   Border.all(),
            color: Colors.blue,
          ),
        ),
      ),
    );
    expect(
      find.byType(DecoratedBox),
      paints
        ..rect(color: Color(Colors.blue.value))
        ..rect(color: Colors.black)
        ..rect(color: Colors.white),
    );
  });

  test('ShapeDecoration with BorderDirectional', () {
    const ShapeDecoration decoration = ShapeDecoration(
      shape: BorderDirectional(start: BorderSide(color: Colors.red, width: 3)),
    );

    expect(decoration.padding, isA<EdgeInsetsDirectional>());
  });

  testWidgets('TestBorder and Directionality - 1', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DecoratedBox(
          decoration: ShapeDecoration(
            shape: TestBorder(log.add),
            color: Colors.green,
          ),
        ),
      ),
    );
    expect(
      log,
      <String>[
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
      ],
    );
  });

  testWidgets('TestBorder and Directionality - 2', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: TestBorder(log.add),
            image: DecorationImage(
              image: image,
            ),
          ),
        ),
      ),
    );
    expect(
      log,
      <String>[
        'getInnerPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
      ],
    );
  });

  testWidgets('Does not crash with directional gradient', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/76967.

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            gradient: RadialGradient(
              focal: AlignmentDirectional.bottomCenter,
              focalRadius: 5,
              radius: 2,
              colors: <Color>[Colors.red, Colors.black],
              stops: <double>[0.0, 0.4],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('ShapeDecoration equality', () {
    const ShapeDecoration a = ShapeDecoration(
      color: Color(0xFFFFFFFF),
      shadows: <BoxShadow>[BoxShadow()],
      shape: Border(),
    );

    const ShapeDecoration b = ShapeDecoration(
      color: Color(0xFFFFFFFF),
      shadows: <BoxShadow>[BoxShadow()],
      shape: Border(),
    );

    expect(a.hashCode, equals(b.hashCode));
    expect(a, equals(b));
  });

  testWidgets('OutlinedBorder avoids clipping edges when possible', (WidgetTester tester) async {
    // Fix https://github.com/flutter/flutter/issues/13675
    final Key key = UniqueKey();
    Widget buildWidget(Color color) {
      List<Widget> circles = [];
      for (int i = 50; i > 0; i--) {
        double radius = i * 2.5;
        double angle = i * 0.5;
        double x = radius * math.cos(angle);
        double y = radius * math.sin(angle);
        Widget circle = Positioned(
          left: 150 - x,
          top: 150 - y,
          child: Container(
            width: 200,
            height: 200,
            decoration: ShapeDecoration(
              color: Colors.black,
              shape: CircleBorder(
                side: BorderSide(
                  color: Colors.white.withOpacity(0.99),
                  width: 50,
                ),
              ),
            ),
          ),
        );
        circles.add(circle);
      }

      return Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(75),
          border: Border.all(
            color: Colors.black,
            width: 1,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Stack(
          children: circles,
        ),
      );
    }

    await tester.pumpWidget(buildWidget(const Color(0xffffffff)));
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('painting.shape_decoration.outlined_border.should_be_white.png'),
    );

    await tester.pumpWidget(buildWidget(const Color(0xfaffffff)));
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('painting.shape_decoration.outlined_border.show_lines_due_to_opacity.png'),
    );
  });
}
