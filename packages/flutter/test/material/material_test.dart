// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NotifyMaterial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    new LayoutChangedNotification().dispatch(context);
    return new Container();
  }
}

class PaintRecorder extends CustomPainter {
  PaintRecorder(this.log);

  List<Size> log;

  @override
  void paint(Canvas canvas, Size size) {
    log.add(size);
    final Paint paint = new Paint()..color = const Color(0xFF0000FF);
    canvas.drawRect(Point.origin & size, paint);
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

    await tester.scroll(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pump();

    expect(log, isEmpty);
  });
}
