// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Route<void> generateRoute(final RouteSettings settings) => PageRouteBuilder<void>(
  settings: settings,
  pageBuilder: (final BuildContext context, final Animation<double> animation1, final Animation<double> animation2) {
    return const Placeholder();
  },
);

void main() {
  testWidgets('WidgetsApp.navigatorKey', (final WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(WidgetsApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      onGenerateRoute: generateRoute,
    ));
    expect(key.currentState, isA<NavigatorState>());
    await tester.pumpWidget(WidgetsApp(
      color: const Color(0xFF112233),
      onGenerateRoute: generateRoute,
    ));
    expect(key.currentState, isNull);
    await tester.pumpWidget(WidgetsApp(
      navigatorKey: key,
      color: const Color(0xFF112233),
      onGenerateRoute: generateRoute,
    ));
    expect(key.currentState, isA<NavigatorState>());
  });
}
