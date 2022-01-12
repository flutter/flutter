// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('Transform origin', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 100.0,
              child: SizedBox(
                width: 100.0,
                height: 100.0,
                child: Transform(
                  transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  origin: const Offset(100.0, 50.0),
                  child: GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: Container(
                      color: const Color(0xFF00FFFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Transform alignment', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 100.0,
              child: SizedBox(
                width: 100.0,
                height: 100.0,
                child: Transform(
                  transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: Container(
                      color: const Color(0xFF00FFFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Transform AlignmentDirectional alignment', (WidgetTester tester) async {
    bool didReceiveTap = false;

    Widget buildFrame(TextDirection textDirection, AlignmentGeometry alignment) {
      return Directionality(
        textDirection: textDirection,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 100.0,
              child: SizedBox(
                width: 100.0,
                height: 100.0,
                child: Transform(
                  transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  alignment: alignment,
                  child: GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: Container(
                      color: const Color(0xFF00FFFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr, AlignmentDirectional.centerEnd));
    didReceiveTap = false;
    await tester.tapAt(const Offset(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isTrue);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, AlignmentDirectional.centerStart));
    didReceiveTap = false;
    await tester.tapAt(const Offset(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isTrue);

    await tester.pumpWidget(buildFrame(TextDirection.ltr, AlignmentDirectional.centerStart));
    didReceiveTap = false;
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(110.0, 150.0));
    expect(didReceiveTap, isTrue);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, AlignmentDirectional.centerEnd));
    didReceiveTap = false;
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(110.0, 150.0));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Transform offset + alignment', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 100.0,
              child: SizedBox(
                width: 100.0,
                height: 100.0,
                child: Transform(
                  transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  origin: const Offset(100.0, 0.0),
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: Container(
                      color: const Color(0xFF00FFFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    await tester.tapAt(const Offset(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Composited transform offset', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 400.0,
          height: 300.0,
          child: ClipRect(
            child: Transform(
              transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
              child: Opacity(
                opacity: 0.9,
                child: Container(
                  color: const Color(0xFF00FF00),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final List<Layer> layers = tester.layers
      ..retainWhere((Layer layer) => layer is TransformLayer);
    expect(layers.length, 2);
    // The first transform is from the render view.
    final TransformLayer layer = layers[1] as TransformLayer;
    final Matrix4 transform = layer.transform!;
    expect(transform.getTranslation(), equals(Vector3(100.0, 75.0, 0.0)));
  });

  testWidgets('Transform.rotate', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.rotate(
        angle: math.pi / 2.0,
        child: Opacity(opacity: 0.5, child: Container()),
      ),
    );

    final List<Layer> layers = tester.layers
      ..retainWhere((Layer layer) => layer is TransformLayer);
    expect(layers.length, 2);
    // The first transform is from the render view.
    final TransformLayer layer = layers[1] as TransformLayer;
    final Matrix4 transform = layer.transform!;
    expect(transform.storage, <dynamic>[
      moreOrLessEquals(0.0), 1.0, 0.0, 0.0,
      -1.0, moreOrLessEquals(0.0), 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      700.0, -100.0, 0.0, 1.0,
    ]);
  });

  testWidgets('applyPaintTransform of Transform in Padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      Padding(
        padding: const EdgeInsets.only(
          left: 30.0,
          top: 20.0,
          right: 50.0,
          bottom: 70.0,
        ),
        child: Transform(
          transform: Matrix4.diagonal3Values(2.0, 2.0, 2.0),
          child: const Placeholder(),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(30.0, 20.0));
  });

  testWidgets('Transform.translate', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.translate(
        offset: const Offset(100.0, 50.0),
        child: Opacity(opacity: 0.5, child: Container()),
      ),
    );

    // This should not cause a transform layer to be inserted.
    final List<Layer> layers = tester.layers
      ..retainWhere((Layer layer) => layer is TransformLayer);
    expect(layers.length, 1); // only the render view
    expect(tester.getTopLeft(find.byType(Container)), const Offset(100.0, 50.0));
  });

  testWidgets('Transform.scale', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.scale(
        scale: 2.0,
        child: Opacity(opacity: 0.5, child: Container()),
      ),
    );

    final List<Layer> layers = tester.layers
      ..retainWhere((Layer layer) => layer is TransformLayer);
    expect(layers.length, 2);
    // The first transform is from the render view.
    final TransformLayer layer = layers[1] as TransformLayer;
    final Matrix4 transform = layer.transform!;
    expect(transform.storage, <dynamic>[
      // These are column-major, not row-major.
      2.0, 0.0, 0.0, 0.0,
      0.0, 2.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      -400.0, -300.0, 0.0, 1.0, // it's 1600x1200, centered in an 800x600 square
    ]);
  });

  testWidgets('Translated child into translated box - hit test', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    bool _pointerDown = false;
    await tester.pumpWidget(
      Transform.translate(
        offset: const Offset(100.0, 50.0),
        child: Transform.translate(
          offset: const Offset(1000.0, 1000.0),
          child: Listener(
            onPointerDown: (PointerDownEvent event) {
              _pointerDown = true;
            },
            child: Container(
              key: key1,
              color: const Color(0xFF000000),
            ),
          ),
        ),
      ),
    );
    expect(_pointerDown, isFalse);
    await tester.tap(find.byKey(key1));
    expect(_pointerDown, isTrue);
  });

  Widget _generateTransform(bool needsCompositing, double angle) {
    final Widget customPaint = CustomPaint(painter: TestRectPainter());
    return Transform(
      transform: MatrixUtils.createCylindricalProjectionTransform(
        radius: 100,
        angle: angle,
        perspective: 0.003,
      ),
      // A RepaintBoundary child forces the Transform to needsCompositing
      child: needsCompositing ? RepaintBoundary(child: customPaint) : customPaint,
    );
  }

  testWidgets(
    '3D transform renders the same with or without needsCompositing',
    (WidgetTester tester) async {
      for (double angle = 0; angle <= math.pi/4; angle += 0.01) {
        await tester.pumpWidget(RepaintBoundary(child: _generateTransform(true, angle)));
        final RenderBox renderBox = tester.binding.renderView.child!;
        final OffsetLayer layer = renderBox.debugLayer! as OffsetLayer;
        final ui.Image imageWithCompositing = await layer.toImage(renderBox.paintBounds);

        await tester.pumpWidget(RepaintBoundary(child: _generateTransform(false, angle)));
        await expectLater(find.byType(RepaintBoundary).first, matchesReferenceImage(imageWithCompositing));
      }
    },
    skip: isBrowser, // due to https://github.com/flutter/flutter/issues/49857
  );

  List<double> extractMatrix(ui.ImageFilter? filter) {
    final List<String> numbers = filter.toString().split('[').last.split(']').first.split(',');
    return numbers.map<double>((String str) => double.parse(str.trim())).toList();
  }

  testWidgets('Transform.translate with FilterQuality produces filter layer', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.translate(
        offset: const Offset(25.0, 25.0),
        filterQuality: FilterQuality.low,
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>().length, 1);
    final ImageFilterLayer layer = tester.layers.whereType<ImageFilterLayer>().first;
    expect(extractMatrix(layer.imageFilter), <double>[
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      25.0, 25.0, 0.0, 1.0]
    );
  });

  testWidgets('Transform.scale with FilterQuality produces filter layer', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.scale(
        scale: 3.14159,
        filterQuality: FilterQuality.low,
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>().length, 1);
    final ImageFilterLayer layer = tester.layers.whereType<ImageFilterLayer>().first;
    expect(extractMatrix(layer.imageFilter), <double>[
      3.14159, 0.0, 0.0, 0.0,
      0.0, 3.14159, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      -856.636, -642.477, 0.0, 1.0]
    );
  });

  testWidgets('Transform.rotate with FilterQuality produces filter layer', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.rotate(
        angle: math.pi / 4,
        filterQuality: FilterQuality.low,
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>().length, 1);
    final ImageFilterLayer layer = tester.layers.whereType<ImageFilterLayer>().first;
    expect(extractMatrix(layer.imageFilter), <dynamic>[
      moreOrLessEquals(0.7071067811865476), moreOrLessEquals(0.7071067811865475), 0.0, 0.0,
      moreOrLessEquals(-0.7071067811865475), moreOrLessEquals(0.7071067811865476), 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      moreOrLessEquals(329.28932188134524), moreOrLessEquals(-194.97474683058329), 0.0, 1.0]
    );
  });

  testWidgets('Offset Transform.rotate with FilterQuality produces filter layer', (WidgetTester tester) async {
    await tester.pumpWidget(
      SizedBox(width: 400, height: 400,
        child: Center(
          child: Transform.rotate(
            angle: math.pi / 4,
            filterQuality: FilterQuality.low,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>().length, 1);
    final ImageFilterLayer layer = tester.layers.whereType<ImageFilterLayer>().first;
    expect(extractMatrix(layer.imageFilter), <dynamic>[
      moreOrLessEquals(0.7071067811865476), moreOrLessEquals(0.7071067811865475), 0.0, 0.0,
      moreOrLessEquals(-0.7071067811865475), moreOrLessEquals(0.7071067811865476), 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      moreOrLessEquals(329.28932188134524), moreOrLessEquals(-194.97474683058329), 0.0, 1.0]
    );
  });

  testWidgets('Transform layers update to match child and filterQuality', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.rotate(
        angle: math.pi / 4,
        filterQuality: FilterQuality.low,
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>(), hasLength(1));

    await tester.pumpWidget(
      Transform.rotate(
        angle: math.pi / 4,
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>(), isEmpty);

    await tester.pumpWidget(
      Transform.rotate(
        angle: math.pi / 4,
        filterQuality: FilterQuality.low,
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>(), isEmpty);

    await tester.pumpWidget(
      Transform.rotate(
        angle: math.pi / 4,
        filterQuality: FilterQuality.low,
        child: const SizedBox(width: 100, height: 100),
      ),
    );
    expect(tester.layers.whereType<ImageFilterLayer>(), hasLength(1));
  });

  testWidgets('Transform layers with filterQuality golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          crossAxisCount: 3,
          children: <Widget>[
            Transform.rotate(
              angle: math.pi / 6,
              child: Center(child: Container(width: 100, height: 20, color: const Color(0xffffff00))),
            ),
            Transform.scale(
              scale: 1.5,
              child: Center(child: Container(width: 100, height: 20, color: const Color(0xffffff00))),
            ),
            Transform.translate(
              offset: const Offset(20.0, 60.0),
              child: Center(child: Container(width: 100, height: 20, color: const Color(0xffffff00))),
            ),
            Transform.rotate(
              angle: math.pi / 6,
              filterQuality: FilterQuality.low,
              child: Center(child: Container(width: 100, height: 20, color: const Color(0xff00ff00))),
            ),
            Transform.scale(
              scale: 1.5,
              filterQuality: FilterQuality.low,
              child: Center(child: Container(width: 100, height: 20, color: const Color(0xff00ff00))),
            ),
            Transform.translate(
              offset: const Offset(20.0, 60.0),
              filterQuality: FilterQuality.low,
              child: Center(child: Container(width: 100, height: 20, color: const Color(0xff00ff00))),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(GridView),
      matchesGoldenFile('transform_golden.BitmapRotate.png'),
    );
  });

  testWidgets("Transform.scale() does not accept all three 'scale', 'scaleX' and 'scaleY' parameters to be non-null", (WidgetTester tester) async {
    await expectLater(() {
      tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Transform.scale(
              scale: 1.0,
              scaleX: 1.0,
              scaleY: 1.0,
              child: const SizedBox(
                height: 100,
                width: 100,
              ),
            ),
          )));
    }, throwsAssertionError);
  });

  testWidgets("Transform.scale() needs at least one of 'scale', 'scaleX' and 'scaleY' to be non-null, otherwise throws AssertionError", (WidgetTester tester) async {
    await expectLater(() {
      tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Transform.scale(
              child: const SizedBox(
                height: 100,
                width: 100,
              ),
            ),
          )));
    }, throwsAssertionError);
  });

  testWidgets("Transform.scale() scales widget uniformly with 'scale' parameter", (WidgetTester tester) async {
    const double _scale = 1.5;
    const double _height = 100;
    const double _width = 150;
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 400,
          width: 400,
          child: Center(
            child: Transform.scale(
              scale: _scale,
              child: Container(
                height: _height,
                width: _width,
                decoration: const BoxDecoration(),
              ),
            ),
          ),
        )));

    const Size _target = Size(_width * _scale, _height * _scale);

    expect(tester.getBottomRight(find.byType(Container)), _target.bottomRight(tester.getTopLeft(find.byType(Container))));
  });

  testWidgets("Transform.scale() scales widget according to 'scaleX' and 'scaleY'", (WidgetTester tester) async {
    const double _scaleX = 1.5;
    const double _scaleY = 1.2;
    const double _height = 100;
    const double _width = 150;
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 400,
          width: 400,
          child: Center(
            child: Transform.scale(
              scaleX: _scaleX,
              scaleY: _scaleY,
              child: Container(
                height: _height,
                width: _width,
                decoration: const BoxDecoration(),
              ),
            ),
          ),
        )));

    const Size _target = Size(_width * _scaleX, _height * _scaleY);

    expect(tester.getBottomRight(find.byType(Container)), _target.bottomRight(tester.getTopLeft(find.byType(Container))));
  });
}

class TestRectPainter extends CustomPainter {
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawRect(
      const Offset(200, 200) & const Size(10, 10),
      Paint()..color = const Color(0xFFFF0000),
    );
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
