// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Padding RTL', (WidgetTester tester) async {
    const Widget child = const Padding(
      padding: const EdgeInsetsDirectional.only(start: 10.0),
      child: const Placeholder(),
    );
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    ));
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(10.0, 0.0));
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    ));
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(0.0, 0.0));

    await tester.pumpWidget(
      const Padding(
        key: const GlobalObjectKey<Null>(null),
        padding: const EdgeInsets.only(left: 1.0),
      ),
    );
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: const Padding(
        key: const GlobalObjectKey<Null>(null),
        padding: const EdgeInsetsDirectional.only(start: 1.0),
      ),
    ));
    await tester.pumpWidget(
      const Padding(
        key: const GlobalObjectKey<Null>(null),
        padding: const EdgeInsets.only(left: 1.0),
      ),
    );
  });

  testWidgets('Container padding/margin RTL', (WidgetTester tester) async {
    final Widget child = new Container(
      padding: const EdgeInsetsDirectional.only(start: 6.0),
      margin: const EdgeInsetsDirectional.only(end: 20.0, start: 4.0),
      child: const Placeholder(),
    );
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    ));
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(10.0, 0.0));
    expect(tester.getTopRight(find.byType(Placeholder)), const Offset(780.0, 0.0));
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    ));
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 0.0));
    expect(tester.getTopRight(find.byType(Placeholder)), const Offset(790.0, 0.0));
  });

  testWidgets('Container padding/margin mixed RTL/absolute', (WidgetTester tester) async {
    final Widget child = new Container(
      padding: const EdgeInsets.only(left: 6.0),
      margin: const EdgeInsetsDirectional.only(end: 20.0, start: 4.0),
      child: const Placeholder(),
    );
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    ));
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(10.0, 0.0));
    expect(tester.getTopRight(find.byType(Placeholder)), const Offset(780.0, 0.0));
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    ));
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(26.0, 0.0));
    expect(tester.getTopRight(find.byType(Placeholder)), const Offset(796.0, 0.0));
  });

  testWidgets('EdgeInsetsDirectional without Directionality', (WidgetTester tester) async {
    await tester.pumpWidget(const Padding(padding: const EdgeInsetsDirectional.only()));
    expect(tester.takeException(), isAssertionError);
  });
}
