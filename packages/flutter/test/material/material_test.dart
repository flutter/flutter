// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class NotifyMaterial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    new LayoutChangedNotification().dispatch(context);
    return new Container();
  }
}

Widget buildMaterial(int elevation) {
  return new Center(
    child: new SizedBox(
      height: 100.0,
      width: 100.0,
      child: new Material(
        color: const Color(0xFF00FF00),
        elevation: elevation,
      ),
    ),
  );
}

List<BoxShadow> getShadow(WidgetTester tester) {
  final RenderDecoratedBox box = tester.renderObject(find.byType(DecoratedBox).first);
  final BoxDecoration decoration = box.decoration;
  return decoration.boxShadow;
}

class PaintRecorder extends CustomPainter {
  PaintRecorder(this.log);

  final List<Size> log;

  @override
  void paint(Canvas canvas, Size size) {
    log.add(size);
    final Paint paint = new Paint()..color = const Color(0xFF0000FF);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(PaintRecorder oldDelegate) => false;
}

void main() {
  testWidgets('LayoutChangedNotificaion test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new NotifyMaterial(),
      ),
    );
  });

  testWidgets('ListView scroll does not repaint', (WidgetTester tester) async {
    final List<Size> log = <Size>[];

    await tester.pumpWidget(
      new Column(
        children: <Widget>[
          new SizedBox(
            width: 150.0,
            height: 150.0,
            child: new CustomPaint(
              painter: new PaintRecorder(log),
            ),
          ),
          new Expanded(
            child: new Material(
              child: new Column(
                children: <Widget>[
                  new Expanded(
                    child: new ListView(
                      children: <Widget>[
                        new Container(
                          height: 2000.0,
                          decoration: const BoxDecoration(
                            backgroundColor: const Color(0xFF00FF00),
                          ),
                        ),
                      ],
                    ),
                  ),
                  new SizedBox(
                    width: 100.0,
                    height: 100.0,
                    child: new CustomPaint(
                      painter: new PaintRecorder(log),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // We paint twice because we have two CustomPaint widgets in the tree above
    // to test repainting both inside and outside the Material widget.
    expect(log, equals(<Size>[
      const Size(150.0, 150.0),
      const Size(100.0, 100.0),
    ]));
    log.clear();

    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pump();

    expect(log, isEmpty);
  });

  testWidgets('Shadows animate smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(buildMaterial(0));
    final List<BoxShadow> shadowA = getShadow(tester);

    await tester.pumpWidget(buildMaterial(9));
    final List<BoxShadow> shadowB = getShadow(tester);

    await tester.pump(const Duration(milliseconds: 1));
    final List<BoxShadow> shadowC = getShadow(tester);

    await tester.pump(kThemeChangeDuration ~/ 2);
    final List<BoxShadow> shadowD = getShadow(tester);

    await tester.pump(kThemeChangeDuration);
    final List<BoxShadow> shadowE = getShadow(tester);

    // This code verifies the following:
    //  1. When the elevation is zero, there's no shadow.
    //  2. When the elevation isn't zero, there's three shadows.
    //  3. When the elevation changes from 0 to 9, one millisecond later, the
    //     shadows are still more or less indistinguishable from zero.
    //  4. Have a kThemeChangeDuration later, they are distinguishable form
    //     zero.
    //  5. ...but still distinguishable from the actual 9 elevation.
    //  6. After kThemeChangeDuration, the shadows are exactly the elevation 9
    //     shadows.
    // The point being to verify that the shadows animate, and do so
    // continually, not in discrete increments (e.g. not jumping from elevation
    // 0 to 1 to 2 to 3 and so forth).

    // TODO(ianh): Port this test when we turn the physical model back on.

    // 1
    expect(shadowA, isNull);
    expect(shadowB, isNull);
    // 2
    expect(shadowC, hasLength(3));
    // 3
    expect(shadowC[0].offset.dy, closeTo(0.0, 0.001));
    expect(shadowC[1].offset.dy, closeTo(0.0, 0.001));
    expect(shadowC[2].offset.dy, closeTo(0.0, 0.001));
    expect(shadowC[0].blurRadius, closeTo(0.0, 0.001));
    expect(shadowC[1].blurRadius, closeTo(0.0, 0.001));
    expect(shadowC[2].blurRadius, closeTo(0.0, 0.001));
    expect(shadowC[0].spreadRadius, closeTo(0.0, 0.001));
    expect(shadowC[1].spreadRadius, closeTo(0.0, 0.001));
    expect(shadowC[2].spreadRadius, closeTo(0.0, 0.001));
    // 4
    expect(shadowD[0].offset.dy, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[1].offset.dy, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[2].offset.dy, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[0].blurRadius, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[1].blurRadius, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[2].blurRadius, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[0].spreadRadius, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[1].spreadRadius, isNot(closeTo(0.0, 0.001)));
    expect(shadowD[2].spreadRadius, isNot(closeTo(0.0, 0.001)));
    // 5
    expect(shadowD[0], isNot(shadowE[0]));
    expect(shadowD[1], isNot(shadowE[1]));
    expect(shadowD[2], isNot(shadowE[2]));
    // 6
    expect(shadowE, kElevationToShadow[9]);
  });
}
