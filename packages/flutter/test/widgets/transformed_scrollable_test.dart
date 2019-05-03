// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

void main() {
  testWidgets('Scrollable scaled up', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Transform.scale(
          scale: 2.0,
          child: Center(
            child: Container(
              width: 200,
              child: ListView.builder(
                controller: controller,
                cacheExtent: 0.0,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 100.0,
                    color: index % 2 == 0 ? Colors.blue : Colors.red,
                    child: Text('Tile $index'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(controller.offset, 0.0);

    await tester.drag(find.byType(ListView), const Offset(0.0, -100.0));
    await tester.pump();
    expect(controller.offset, 50.0); // 100.0 / 2.0

    await tester.drag(find.byType(ListView), const Offset(80.0, -70.0));
    await tester.pump();
    expect(controller.offset, 85.0); // 50.0 + (70.0 / 2)

    await tester.drag(find.byType(ListView), const Offset(100.0, 0.0));
    await tester.pump();
    expect(controller.offset, 85.0);

    await tester.drag(find.byType(ListView), const Offset(0.0, 85.0));
    await tester.pump();
    expect(controller.offset, 42.5); // 85.0 - (85.0 / 2)
  });

  testWidgets('Scrollable scaled down', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Transform.scale(
          scale: 0.5,
          child: Center(
            child: Container(
              width: 200,
              child: ListView.builder(
                controller: controller,
                cacheExtent: 0.0,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 100.0,
                    color: index % 2 == 0 ? Colors.blue : Colors.red,
                    child: Text('Tile $index'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(controller.offset, 0.0);

    await tester.drag(find.byType(ListView), const Offset(0.0, -100.0));
    await tester.pump();
    expect(controller.offset, 200.0); // 100.0 * 2.0

    await tester.drag(find.byType(ListView), const Offset(80.0, -70.0));
    await tester.pump();
    expect(controller.offset, 340.0); // 200.0 + (70.0 * 2)

    await tester.drag(find.byType(ListView), const Offset(100.0, 0.0));
    await tester.pump();
    expect(controller.offset, 340.0);

    await tester.drag(find.byType(ListView), const Offset(0.0, 170.0));
    await tester.pump();
    expect(controller.offset, 0.0); // 340.0 - (170.0 * 2)
  });

  testWidgets('Scrollable rotated 90 degrees', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Transform.rotate(
          angle: math.pi / 2,
          child: Center(
            child: Container(
              width: 200,
              child: ListView.builder(
                controller: controller,
                cacheExtent: 0.0,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 100.0,
                    color: index % 2 == 0 ? Colors.blue : Colors.red,
                    child: Text('Tile $index'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(controller.offset, 0.0);

    await tester.drag(find.byType(ListView), const Offset(100.0, 0.0));
    await tester.pump();
    expect(controller.offset, 100.0);

    await tester.drag(find.byType(ListView), const Offset(0.0, -100.0));
    await tester.pump();
    expect(controller.offset, 100.0);

    await tester.drag(find.byType(ListView), const Offset(-70.0, -50.0));
    await tester.pump();
    expect(controller.offset, 30.0); // 100.0 - 70.0
  });

//  testWidgets('Perspective transform on scrollable', (WidgetTester tester) async {
//    final ScrollController controller = ScrollController();
//    await tester.pumpWidget(
//      MaterialApp(
//        home: Transform(
//          transform: Matrix4.identity()
//            ..setEntry(3, 2, 0.001)
//            ..rotateY(-0.01 * 90),
//          child: Center(
//            child: Container(
//              width: 200,
//              child: ListView.builder(
//                controller: controller,
//                cacheExtent: 0.0,
//                itemBuilder: (BuildContext context, int index) {
//                  return Container(
//                    height: 100.0,
//                    color: index % 2 == 0 ? Colors.blue : Colors.red,
//                    child: Text('Tile $index'),
//                  );
//                },
//              ),
//            ),
//          ),
//        ),
//      ),
//    );
//    expect(controller.offset, 0.0);
//  });
}
