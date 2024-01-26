// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResponsiveBuilder', (WidgetTester tester) async {
    Future<void> pump(Size size) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: ResponsiveBuilder(
            builder: (BuildContext context, WindowSizeClass windowSizeClass) =>
              Container(key: ObjectKey(windowSizeClass)),
          )
        ));
    }

    await pump(const Size(500, 100));
    expect(find.byKey(const ObjectKey(WindowSizeClass.compact)), findsOneWidget);
    await pump(const Size(700, 100));
    expect(find.byKey(const ObjectKey(WindowSizeClass.medium)), findsOneWidget);
    await pump(const Size(1000, 100));
    expect(find.byKey(const ObjectKey(WindowSizeClass.expanded)), findsOneWidget);
    await pump(const Size(1300, 100));
    expect(find.byKey(const ObjectKey(WindowSizeClass.large)), findsOneWidget);
    await pump(const Size(2000, 100));
    expect(find.byKey(const ObjectKey(WindowSizeClass.extraLarge)), findsOneWidget);
  });
}
