// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_page_tester.dart';

void main() {
  testWidgets('TestPage builds and works with Navigator', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          pages: const <Page<Object?>>[TestPage<void>(child: Text('Page 1'))],
          onPopPage: (Route<Object?> route, Object? result) => false,
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
  });

  testWidgets('TestPage passes properties to PageRouteBuilder', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigatorKey,
          pages: const <Page<Object?>>[
            TestPage<void>(
              name: '/test',
              maintainState: false,
              fullscreenDialog: true,
              allowSnapshotting: false,
              child: Text('Page'),
            ),
          ],
          onPopPage: (Route<Object?> route, Object? result) => false,
        ),
      ),
    );

    final Route<dynamic> route = ModalRoute.of(tester.element(find.text('Page')))!;
    expect(route is PageRouteBuilder, isTrue);
    final pageRoute = route as PageRouteBuilder<dynamic>;

    expect(pageRoute.settings.name, '/test');
    expect(pageRoute.maintainState, false);
    expect(pageRoute.fullscreenDialog, true);
    expect(pageRoute.allowSnapshotting, false);
  });
}
