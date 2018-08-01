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
        alignment: const Alignment(0.50, 0.50),
      ),
    );

    await tester.pumpWidget(
      new Align(
        child: new Container(),
        alignment: const Alignment(0.0, 0.0),
      ),
    );

    await tester.pumpWidget(
      const Align(
        key: const GlobalObjectKey<Null>(null),
        alignment: Alignment.topLeft,
      ),
    );
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: const Align(
        key: const GlobalObjectKey<Null>(null),
        alignment: AlignmentDirectional.topStart,
      ),
    ));
    await tester.pumpWidget(
      const Align(
        key: const GlobalObjectKey<Null>(null),
        alignment: Alignment.topLeft,
      ),
    );
  });

  testWidgets('Align control test (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: AlignmentDirectional.topStart,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: Alignment.topLeft,
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
        alignment: AlignmentDirectional.topStart,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 700.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 800.0);

    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Align(
        child: new Container(width: 100.0, height: 80.0),
        alignment: Alignment.topLeft,
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
          alignment: const Alignment(0.0, 0.0),
        ),
      ),
    );

    final Size size = alignKey.currentContext.size;
    expect(size.width, equals(800.0));
    expect(size.height, equals(10.0));
  });
}
