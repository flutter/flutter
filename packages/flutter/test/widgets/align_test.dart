// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Align smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Align(
        child: Container(),
        alignment: const Alignment(0.50, 0.50),
      ),
    );

    await tester.pumpWidget(
      Align(
        child: Container(),
        alignment: const Alignment(0.0, 0.0),
      ),
    );

    await tester.pumpWidget(
      const Align(
        key: GlobalObjectKey<State<StatefulWidget>>(null),
        alignment: Alignment.topLeft,
      ),
    );
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        key: GlobalObjectKey<State<StatefulWidget>>(null),
        alignment: AlignmentDirectional.topStart,
      ),
    ));
    await tester.pumpWidget(
      const Align(
        key: GlobalObjectKey<State<StatefulWidget>>(null),
        alignment: Alignment.topLeft,
      ),
    );
  });

  testWidgets('Align control test (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        child: Container(width: 100.0, height: 80.0),
        alignment: AlignmentDirectional.topStart,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        child: Container(width: 100.0, height: 80.0),
        alignment: Alignment.topLeft,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);
  });

  testWidgets('Align control test (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        child: Container(width: 100.0, height: 80.0),
        alignment: AlignmentDirectional.topStart,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 700.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 800.0);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        child: Container(width: 100.0, height: 80.0),
        alignment: Alignment.topLeft,
      ),
    ));

    expect(tester.getTopLeft(find.byType(Container)).dx, 0.0);
    expect(tester.getBottomRight(find.byType(Container)).dx, 100.0);
  });

  testWidgets('Shrink wraps in finite space', (WidgetTester tester) async {
    final GlobalKey alignKey = GlobalKey();
    await tester.pumpWidget(
      SingleChildScrollView(
        child: Align(
          key: alignKey,
          child: Container(
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
