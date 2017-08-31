// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Align smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Align(
        child: new Container(),
        alignment: const FractionalOffset(0.75, 0.75),
      ),
    );

    await tester.pumpWidget(
      new Align(
        child: new Container(),
        alignment: const FractionalOffset(0.5, 0.5),
      ),
    );
  });

  testWidgets('Align control test (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: FractionalOffsetDirectional.topStart,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: FractionalOffset.topLeft,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);
  });

  testWidgets('Align control test (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.rtl,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: FractionalOffsetDirectional.topStart,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 700.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 800.0);

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: FractionalOffset.topLeft,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);
  });

  testWidgets('Shrink wraps in finite space', (WidgetTester tester) async {
    final GlobalKey alignKey = new GlobalKey();
    await tester.pumpWidget(
      new SingleChildScrollView(
        child: new Align(
          key: alignKey,
          child: new Container(
            width: 10.0,
            height: 10.0
          ),
          alignment: const FractionalOffset(0.50, 0.50),
        ),
      ),
    );

    final Size size = alignKey.currentContext.size;
    expect(size.width, equals(800.0));
    expect(size.height, equals(10.0));
  });
}
