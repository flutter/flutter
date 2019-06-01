// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WidgetsApp with builder only', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      WidgetsApp(
        key: key,
        builder: (BuildContext context, Widget child) {
          return const Placeholder();
        },
        color: const Color(0xFF123456),
      ),
    );
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('Navigator routes wrapper builder', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    bool didBuild = false;
    await tester.pumpWidget(
      WidgetsApp(
        onGenerateRoute: (RouteSettings settings) => null,
        onUnknownRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(builder: (BuildContext context) {
            return const Placeholder();
          });
        },
        navigatorRoutesWrapperBuilder: (BuildContext context, Widget child) {
          expect(context.ancestorWidgetOfExactType(WidgetsApp), isNotNull);
          expect(context.ancestorWidgetOfExactType(Navigator), isNotNull);
          didBuild = true;

          return Container(key: key, child: child,);
        },
        color: const Color(0xFF123456),
      ),
    );
    expect(didBuild, isTrue);

    expect(find.byType(Overlay), isNotNull);
    expect(find.byType(Navigator), isNotNull);
    expect(find.byKey(key), findsOneWidget);
  });
}
