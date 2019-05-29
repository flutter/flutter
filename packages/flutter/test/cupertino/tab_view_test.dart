// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import '../painting/mocks_for_image_cache.dart';

typedef IntCallback = void Function(int);

class MockNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) => stackDepth++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) => stackDepth--;
}

final List<int> tabsPainted = <int>[];
final List<int> selectedTabs = <int>[];
final CupertinoTabController controller = CupertinoTabController();
MockNavigatorObserver mockObserver;
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
      navigatorObservers: <NavigatorObserver>[mockObserver],
    );
  };
}

Widget defaultBuilder(BuildContext context) {
  return CupertinoButton(
    onPressed: () => CupertinoPageRoute<dynamic>(builder: defaultBuilder),
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
    mockObserver = MockNavigatorObserver();
  });

  FutureOr<void> push(int times, WidgetTester tester) async {
    if (times < 1) {
      expect(stackDepth, times);
      return;
    }
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    return await push(times - 1, tester);
  }

  void verifyPop(int times) {
    if (times < 1) {
      verifyZeroInteractions(mockObserver);
      return;
    }
    verify(mockObserver.didPop(any, any));
    return verifyPop(times - 1);
  }

  testWidgets('tap when active works', (WidgetTester tester) async {
    await tester.pumpWidget(buildBoilerplate());
    await push(15, tester);

    await tester.tap(find.text('Tab 1'));
    await tester.pump(const Duration(seconds: 2));

    verifyPop(15);
  });
}
