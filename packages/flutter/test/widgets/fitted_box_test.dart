// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can size according to aspect ratio', (WidgetTester tester) async {
    Key outside = new UniqueKey();
    Key inside = new UniqueKey();

    await tester.pumpWidget(
      new Center(
        child: new Container(
          width: 200.0,
          child: new FittedBox(
            key: outside,
            child: new Container(
              key: inside,
              width: 100.0,
              height: 50.0,
            )
          )
        )
      )
    );

    RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
    expect(outsideBox.size.width, 200.0);
    expect(outsideBox.size.height, 100.0);

    RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
    expect(insideBox.size.width, 100.0);
    expect(insideBox.size.height, 50.0);

    Point insidePoint = insideBox.localToGlobal(const Point(100.0, 50.0));
    Point outsidePoint = outsideBox.localToGlobal(const Point(200.0, 100.0));

    expect(outsidePoint, equals(const Point(500.0, 350.0)));
    expect(insidePoint, equals(outsidePoint));
  });

  testWidgets('Can contain child', (WidgetTester tester) async {
    Key outside = new UniqueKey();
    Key inside = new UniqueKey();

    await tester.pumpWidget(
      new Center(
        child: new Container(
          width: 200.0,
          height: 200.0,
          child: new FittedBox(
            key: outside,
            child: new Container(
              key: inside,
              width: 100.0,
              height: 50.0,
            )
          )
        )
      )
    );

    RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
    expect(outsideBox.size.width, 200.0);
    expect(outsideBox.size.height, 200.0);

    RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
    expect(insideBox.size.width, 100.0);
    expect(insideBox.size.height, 50.0);

    Point insidePoint = insideBox.localToGlobal(const Point(100.0, 0.0));
    Point outsidePoint = outsideBox.localToGlobal(const Point(200.0, 50.0));

    expect(insidePoint, equals(outsidePoint));
  });

  testWidgets('Child can conver', (WidgetTester tester) async {
    Key outside = new UniqueKey();
    Key inside = new UniqueKey();

    await tester.pumpWidget(
      new Center(
        child: new Container(
          width: 200.0,
          height: 200.0,
          child: new FittedBox(
            key: outside,
            fit: ImageFit.cover,
            child: new Container(
              key: inside,
              width: 100.0,
              height: 50.0,
            )
          )
        )
      )
    );

    RenderBox outsideBox = tester.firstRenderObject(find.byKey(outside));
    expect(outsideBox.size.width, 200.0);
    expect(outsideBox.size.height, 200.0);

    RenderBox insideBox = tester.firstRenderObject(find.byKey(inside));
    expect(insideBox.size.width, 100.0);
    expect(insideBox.size.height, 50.0);

    Point insidePoint = insideBox.localToGlobal(const Point(50.0, 25.0));
    Point outsidePoint = outsideBox.localToGlobal(const Point(100.0, 100.0));

    expect(insidePoint, equals(outsidePoint));
  });
}
