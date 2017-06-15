// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Middle still in center with asymmetrical actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return const CupertinoNavigationBar(
                leading: const CupertinoButton(child: const Text('Something'), onPressed: null,),
                middle: const Text('Title'),
              );
            },
          );
        },
      ),
    );

    // Expect the middle of the title to be exactly in the middle of the screen.
    expect(tester.getCenter(find.text('Title')).dx, 400.0);
  });

  testWidgets('Opaque background does not add blur effects', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return const CupertinoNavigationBar(
                middle: const Text('Title'),
                backgroundColor: const Color(0xFFE5E5E5),
              );
            },
          );
        },
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('Non-opaque background adds blur effects', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new PageRouteBuilder<Null>(
            settings: settings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return const CupertinoNavigationBar(
                middle: const Text('Title'),
              );
            },
          );
        },
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}