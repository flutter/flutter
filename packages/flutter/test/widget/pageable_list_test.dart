// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

Size pageSize = new Size(600.0, 300.0);
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
  bool itemsWrap: false,
  ViewportAnchor scrollAnchor: ViewportAnchor.start,
  List<int> pages: defaultPages
}) {
  final PageableList list = new PageableList(
    children: pages.map(buildPage),
    itemsWrap: itemsWrap,
    scrollDirection: Axis.horizontal,
    scrollAnchor: scrollAnchor,
    onPageChanged: (int page) { currentPage = page; }
  );

  // The test framework forces the frame to be 800x600, so we need to create
  // an outer container where we can change the size.
  return new Center(
    child: new Container(
      width: pageSize.width, height: pageSize.height, child: list)
  );
}

void page(WidgetTester tester, Offset offset) {
  String itemText = currentPage != null ? currentPage.toString() : '0';
  tester.scroll(find.text(itemText), offset);
  // One frame to start the animation, a second to complete it.
  tester.pump();
  tester.pump(const Duration(seconds: 1));
}

void pageLeft(WidgetTester tester) {
  page(tester, new Offset(-pageSize.width, 0.0));
}

void pageRight(WidgetTester tester) {
  page(tester, new Offset(pageSize.width, 0.0));
}

void main() {
  testWidgets('PageableList with itemsWrap: false', (WidgetTester tester) {
    currentPage = null;
    tester.pumpWidget(buildFrame());
    expect(currentPage, isNull);
    pageLeft(tester);
    expect(currentPage, equals(1));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    pageRight(tester);
    expect(currentPage, equals(0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    pageRight(tester);
    expect(currentPage, equals(0));
  });

  testWidgets('PageableList with end scroll anchor', (WidgetTester tester) {
    currentPage = 5;
    tester.pumpWidget(buildFrame(scrollAnchor: ViewportAnchor.end));
    pageRight(tester);
    expect(currentPage, equals(4));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);

    pageLeft(tester);
    expect(currentPage, equals(5));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsOneWidget);

    pageLeft(tester);
    expect(currentPage, equals(5));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('PageableList with itemsWrap: true', (WidgetTester tester) {
    currentPage = null;
    tester.pumpWidget(buildFrame(itemsWrap: true));
    expect(currentPage, isNull);
    pageLeft(tester);
    expect(currentPage, equals(1));
    pageRight(tester);
    expect(currentPage, equals(0));
    pageRight(tester);
    expect(currentPage, equals(5));
  });

  testWidgets('PageableList with end and itemsWrap: true', (WidgetTester tester) {
    currentPage = 5;
    tester.pumpWidget(buildFrame(itemsWrap: true, scrollAnchor: ViewportAnchor.end));
    pageRight(tester);
    expect(currentPage, equals(4));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);

    pageLeft(tester);
    expect(currentPage, equals(5));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsOneWidget);

    pageLeft(tester);
    expect(currentPage, equals(0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    pageLeft(tester);
    expect(currentPage, equals(1));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('PageableList with two items', (WidgetTester tester) {
    currentPage = null;
    tester.pumpWidget(buildFrame(itemsWrap: true, pages: <int>[0, 1]));
    expect(currentPage, isNull);
    pageLeft(tester);
    expect(currentPage, equals(1));
    pageRight(tester);
    expect(currentPage, equals(0));
    pageRight(tester);
    expect(currentPage, equals(1));
  });

  testWidgets('PageableList with one item', (WidgetTester tester) {
    currentPage = null;
    tester.pumpWidget(buildFrame(itemsWrap: true, pages: <int>[0]));
    expect(currentPage, isNull);
    pageLeft(tester);
    expect(currentPage, equals(0));
    pageRight(tester);
    expect(currentPage, equals(0));
    pageRight(tester);
    expect(currentPage, equals(0));
  });

  testWidgets('PageableList with no items', (WidgetTester tester) {
    currentPage = null;
    tester.pumpWidget(buildFrame(itemsWrap: true, pages: <int>[]));
    expect(currentPage, isNull);
  });

  testWidgets('PageableList resize parent', (WidgetTester tester) {
    tester.pumpWidget(new Container());
    currentPage = null;

    tester.pumpWidget(buildFrame(itemsWrap: true));
    expect(currentPage, isNull);
    pageRight(tester);
    expect(currentPage, equals(5));

    RenderBox box = globalKeys[5].currentContext.findRenderObject();
    expect(box.size.width, equals(pageSize.width));
    expect(box.size.height, equals(pageSize.height));

    pageSize = new Size(pageSize.height, pageSize.width);
    tester.pumpWidget(buildFrame(itemsWrap: true));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsOneWidget);

    box = globalKeys[5].currentContext.findRenderObject();
    expect(box.size.width, equals(pageSize.width));
    expect(box.size.height, equals(pageSize.height));
  });
}
