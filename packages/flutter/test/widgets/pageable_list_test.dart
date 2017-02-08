// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Size pageSize = const Size(600.0, 300.0);
const List<int> defaultPages = const <int>[0, 1, 2, 3, 4, 5];
final List<GlobalKey> globalKeys = defaultPages.map((_) => new GlobalKey()).toList();
int currentPage;

Widget buildPage(int page) {
  return new Container(
    key: globalKeys[page],
    width: pageSize.width,
    height: pageSize.height,
    child: new Text(page.toString())
  );
}

Widget buildFrame({
  bool reverse: false,
  List<int> pages: defaultPages
}) {
  final PageView child = new PageView(
    scrollDirection: Axis.horizontal,
    reverse: reverse,
    onPageChanged: (int page) { currentPage = page; },
    children: pages.map(buildPage).toList(),
  );

  // The test framework forces the frame to be 800x600, so we need to create
  // an outer container where we can change the size.
  return new Center(
    child: new Container(
      width: pageSize.width, height: pageSize.height, child: child,
    ),
  );
}

Future<Null> page(WidgetTester tester, Offset offset) {
  return TestAsyncUtils.guard(() async {
    String itemText = currentPage != null ? currentPage.toString() : '0';
    await tester.scroll(find.text(itemText), offset);
    await tester.pump();
    await tester.pumpUntilNoTransientCallbacks();
  });
}

Future<Null> pageLeft(WidgetTester tester) {
  return page(tester, new Offset(-pageSize.width, 0.0));
}

Future<Null> pageRight(WidgetTester tester) {
  return page(tester, new Offset(pageSize.width, 0.0));
}

void main() {
  testWidgets('PageView default control', (WidgetTester tester) async {
    await tester.pumpWidget(new Center(child: new PageView()));
  });

  testWidgets('PageView control test', (WidgetTester tester) async {
    currentPage = null;
    await tester.pumpWidget(buildFrame());
    expect(currentPage, isNull);
    await pageLeft(tester);
    expect(currentPage, equals(1));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await pageRight(tester);
    expect(currentPage, equals(0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await pageRight(tester);
    expect(currentPage, equals(0));
  });

  testWidgets('PageView with reverse', (WidgetTester tester) async {
    currentPage = null;
    await tester.pumpWidget(buildFrame(reverse: true));
    await pageRight(tester);
    expect(currentPage, equals(1));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await pageLeft(tester);
    expect(currentPage, equals(0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await pageLeft(tester);
    expect(currentPage, equals(0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });
}
