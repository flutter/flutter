// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('Transform origin', (WidgetTester tester) async {
    bool didReceiveTap = false;
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                child: new Transform(
                  transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  origin: const Offset(100.0, 50.0),
                  child: new GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: new Container(
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                child: new Transform(
                  transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  alignment: const Alignment(1.0, 0.0),
                  child: new GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: new Container(
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
      return new Directionality(
        textDirection: textDirection,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                child: new Transform(
                  transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  alignment: alignment,
                  child: new GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: new Container(
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
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            new Positioned(
              top: 100.0,
              left: 100.0,
              child: new Container(
                width: 100.0,
                height: 100.0,
                child: new Transform(
                  transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                  origin: const Offset(100.0, 0.0),
                  alignment: const Alignment(-1.0, 0.0),
                  child: new GestureDetector(
                    onTap: () {
                      didReceiveTap = true;
                    },
                    child: new Container(
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
      new Center(
        child: new SizedBox(
          width: 400.0,
          height: 300.0,
          child: new ClipRect(
            child: new Transform(
              transform: new Matrix4.diagonal3Values(0.5, 0.5, 1.0),
              child: new Opacity(
                opacity: 0.9,
                child: new Container(
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
    final TransformLayer layer = layers[1];
    final Matrix4 transform = layer.transform;
    expect(transform.getTranslation(), equals(new Vector3(100.0, 75.0, 0.0)));
  });

  testWidgets('Transform.rotate', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Transform.rotate(
        angle: math.pi / 2.0,
        child: new Opacity(opacity: 0.5, child: new Container()),
      ),
    );

    final List<Layer> layers = tester.layers
      ..retainWhere((Layer layer) => layer is TransformLayer);
    expect(layers.length, 2);
    // The first transform is from the render view.
    final TransformLayer layer = layers[1];
    final Matrix4 transform = layer.transform;
    expect(transform.storage, <dynamic>[
      moreOrLessEquals(0.0), 1.0, 0.0, 0.0,
      -1.0, moreOrLessEquals(0.0), 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      700.0, -100.0, 0.0, 1.0,
    ]);
  });

  testWidgets('applyPaintTransform of Transform in Padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Padding(
        padding: const EdgeInsets.only(
          left: 30.0,
          top: 20.0,
          right: 50.0,
          bottom: 70.0,
        ),
        child: new Transform(
          transform: new Matrix4.diagonal3Values(2.0, 2.0, 2.0),
          child: const Placeholder(),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(30.0, 20.0));
  });
}
