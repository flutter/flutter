// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart' show TestImageProvider;

typedef IntCallback = void Function(int);

class MockNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    stackDepth++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    stackDepth--;
  }
}

class TestCupertinoTabView extends CupertinoTabView {
  const TestCupertinoTabView({
    Key key,
    WidgetBuilder builder,
    this.onTap,
  }) : super(key: key, builder: builder);

  final VoidCallback onTap;

  @override
  void onTapWhenActive() => onTap();
}

final List<int> tabsPainted = <int>[];
final List<int> selectedTabs = <int>[];
final CupertinoTabController controller = CupertinoTabController();
int stackDepth = 0;

final List<GlobalKey<NavigatorState>> keys = List<GlobalKey<NavigatorState>>.generate(
  100,
  (_) => GlobalKey<NavigatorState>(),
);

IndexedWidgetBuilder buildTabView(WidgetBuilder builder) {
  return (BuildContext context, int index) {
    return CupertinoTabView(
      navigatorKey: keys[index],
      builder: builder,
      navigatorObservers: <NavigatorObserver>[MockNavigatorObserver()]
    );
  };
}

Widget defaultBuilder(BuildContext context) {
  return CupertinoButton(
    onPressed: () => Navigator.push<void>(context, CupertinoPageRoute<void>(builder: defaultBuilder)),
    child: const Text('push'),
  );
}

Widget buildBoilerplate({
    int numOfTabs = 10,
    int selectedTab = 0,
    IntCallback onTap,
    IndexedWidgetBuilder tabBuilder
}) {
  return CupertinoApp(
    home: CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: List<BottomNavigationBarItem>.generate(
          numOfTabs,
          (int index) => BottomNavigationBarItem(
            icon: const ImageIcon(TestImageProvider(24, 24)),
            title: Text('Tab ${index + 1}'),
          ),
        ),
        onTap: onTap ?? (_) => null,
      ),
      controller: controller,
      tabBuilder: tabBuilder ?? buildTabView(defaultBuilder),
    ),
  );
}

void main() {
  setUp(() {
    selectedTabs.clear();
    tabsPainted.clear();
    controller.index = 0;
    stackDepth = 0;
  });

  FutureOr<void> push(int times, WidgetTester tester) async {
    final int initialStackDepth = stackDepth;
    for(int i = 0; i < times; i++) {
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(stackDepth, initialStackDepth + i + 1);
    }
    expect(stackDepth, times + initialStackDepth);
  }

  testWidgets('tap when active works', (WidgetTester tester) async {
    await tester.pumpWidget(buildBoilerplate());
    // The initial route has been pushed.
    expect(stackDepth, 1);

    await push(15, tester);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The animation should play out as if there were only one route was popped.
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Only the bottom-most route is left.
    expect(stackDepth, 1);
  });

  testWidgets('tap when active still works, after switching back to tab 1 from a different tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildBoilerplate());
      // The initial route has been pushed.
      expect(stackDepth, 1);

      await push(15, tester);

      await tester.tap(find.text('Tab 2'));
      await tester.pump();
      // Now there're 2 initial routes, and 15 more.
      expect(stackDepth, 17);

      // Now there're 2 initial routes, and 15 + 20 more.
      await push(20, tester);
      expect(stackDepth, 37);

      await tester.tap(find.text('Tab 1'));
      await tester.pump();
      await tester.tap(find.text('Tab 1'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Only the bottom-most routes are left in tab 1.
      expect(stackDepth, 2 + 20);

      await tester.tap(find.text('Tab 2'));
      await tester.pump();
      await tester.tap(find.text('Tab 2'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(stackDepth, 2);
  });

  testWidgets('tap when active does not do anything if there is nothing to pop',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildBoilerplate());
      // The initial route has been pushed.
      expect(stackDepth, 1);

      await tester.tap(find.text('Tab 1'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(stackDepth, 1);

      await push(15, tester);
      await tester.tap(find.text('Tab 1'));
      await tester.pump();
  });

  testWidgets('Overriding onTapWhenActive works', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(buildBoilerplate(
      tabBuilder: (BuildContext context, int index) {
        return TestCupertinoTabView(builder: defaultBuilder, onTap: () => tapCount++);
      },
    ));

    expect(tapCount, 0);
    for (int i = 5; i > 0; i--) {
      await tester.tap(find.text('Tab $i'));
      await tester.pump();
      // Only tapping on the active tap counts.
      expect(tapCount, 0);
    }

    await tester.tap(find.text('Tab 1'));
    await tester.pump();
    expect(tapCount, 1);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();
    expect(tapCount, 2);

    await tester.tap(find.text('Tab 1'));
    await tester.pump();
    expect(tapCount, 3);

    // Switch away before starting from 0 again.
    await tester.tap(find.text('Tab 10'));
    await tester.pump();

    // Double tap works.
    for (int i = 0; i < 10; i++) {
      final int snapshot = tapCount;
      await tester.tap(find.text('Tab ${i+1}'));
      await tester.pump();
      await tester.tap(find.text('Tab ${i+1}'));
      await tester.pump();
      expect(tapCount, snapshot + 1);
    }
  });
}
