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

Widget buildMaterial(double elevation) {
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

RenderPhysicalModel getShadow(WidgetTester tester) {
  return tester.renderObject(find.byType(PhysicalModel));
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
                          color: const Color(0xFF00FF00),
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
    // This code verifies that the PhysicalModel's elevation animates over
    // a kThemeChangeDuration time interval.

    await tester.pumpWidget(buildMaterial(0.0));
    final RenderPhysicalModel modelA = getShadow(tester);
    expect(modelA.elevation, equals(0.0));

    await tester.pumpWidget(buildMaterial(9.0));
    final RenderPhysicalModel modelB = getShadow(tester);
    expect(modelB.elevation, equals(0.0));

    await tester.pump(const Duration(milliseconds: 1));
    final RenderPhysicalModel modelC = getShadow(tester);
    expect(modelC.elevation, closeTo(0.0, 0.001));

    await tester.pump(kThemeChangeDuration ~/ 2);
    final RenderPhysicalModel modelD = getShadow(tester);
    expect(modelD.elevation, isNot(closeTo(0.0, 0.001)));

    await tester.pump(kThemeChangeDuration);
    final RenderPhysicalModel modelE = getShadow(tester);
    expect(modelE.elevation, equals(9.0));
  });
}
