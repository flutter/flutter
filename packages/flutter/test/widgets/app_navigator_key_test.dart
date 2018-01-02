// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

final RouteFactory generateRoute = (RouteSettings settings) => new PageRouteBuilder<Null>(
  settings: settings,
  pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
    return const Placeholder();
  },
);

void main() {
  testWidgets('WidgetsApp.navigatorKey', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = new GlobalKey<NavigatorState>();
    await tester.pumpWidget(new WidgetsApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      onGenerateRoute: generateRoute,
    ));
    expect(key.currentState, const isInstanceOf<NavigatorState>());
    await tester.pumpWidget(new WidgetsApp(
      color: const Color(0xFF112233),
      onGenerateRoute: generateRoute,
    ));
    expect(key.currentState, isNull);
    await tester.pumpWidget(new WidgetsApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      onGenerateRoute: generateRoute,
    ));
    expect(key.currentState, const isInstanceOf<NavigatorState>());
  });
}
